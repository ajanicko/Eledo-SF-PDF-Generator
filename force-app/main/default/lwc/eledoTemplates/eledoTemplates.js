import { LightningElement, api, wire } from "lwc";
import { createRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import TEMPLATE_OBJECT from "@salesforce/schema/Eledo_Template__c";
import getTemplates from "@salesforce/apex/EledoAPI.getTemplates";
import getObjects from "@salesforce/apex/EledoTemplatesController.getObjects";
import validateSoql from "@salesforce/apex/EledoTemplatesController.validateSoql";
import getTemplate from "@salesforce/apex/EledoTemplatesController.getTemplate";
import ID_FIELD from "@salesforce/schema/Eledo_Template__c.Id";
import NAME_FIELD from "@salesforce/schema/Eledo_Template__c.Name";
import TEMPLATE_ID_FIELD from "@salesforce/schema/Eledo_Template__c.Template_ID__c";
import OBJECT_FIELD from "@salesforce/schema/Eledo_Template__c.Object__c";
import SOQL_FIELD from "@salesforce/schema/Eledo_Template__c.SOQL__c";

export default class EledoTemplates extends NavigationMixin(LightningElement) {
    @api recordId;
    eledoTemplates;
    templateValue = "";
    selectedTemplate = {};
    objects;
    objectsValue = "";
    soqlValue = "";
    modalHeader = "";
    objectChoiceWrapperClass = "slds-form-element";
    objectChoiceErrorClass =
        "object-choice-error slds-form-element__help slds-hidden";
    showSpinner = false;
    nameField;
    templateIdField;
    objectField;
    soqlField;

    connectedCallback() {
        if (this.recordId) {
            this.showSpinner = true;
            this.modalHeader = "Update Template";
            getTemplate({ recordId: this.recordId })
                .then((template) => {
                    this.templateValue =
                        template[TEMPLATE_ID_FIELD.fieldApiName];
                    this.selectedTemplate = {
                        label: template.Name,
                        value: this.templateValue
                    };
                    this.objectsValue = template[OBJECT_FIELD.fieldApiName];
                    this.soqlValue = template[SOQL_FIELD.fieldApiName];
                })
                .catch((error) => {
                    console.log(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Failed to load Template",
                            message: error.body.message,
                            variant: "error"
                        })
                    );
                })
                .finally(() => {
                    this.showSpinner = false;
                });
        } else {
            this.modalHeader = "New Template";
        }
    }

    renderedCallback() {
        //bind datalist with input after render due to SF randomizing ids
        setTimeout(() =>
            this.template
                .querySelector(".object-choice")
                .setAttribute(
                    "list",
                    this.template.querySelector(".objects").id
                )
        );
    }

    @wire(getObjectInfo, { objectApiName: TEMPLATE_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            //the reason we are cutting it into fields is due to namespace prefix on custom fields
            this.nameField = data.fields[NAME_FIELD.fieldApiName];
            this.templateIdField = data.fields[TEMPLATE_ID_FIELD.fieldApiName];
            this.objectField = data.fields[OBJECT_FIELD.fieldApiName];
            this.soqlField = data.fields[SOQL_FIELD.fieldApiName];
        } else if (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Failed to fetch ObjectInfo",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
    }

    @wire(getTemplates)
    wiredTemplates({ error, data }) {
        if (data) {
            this.eledoTemplates = JSON.parse(data);
            this.eledoTemplates = this.eledoTemplates.templates.map(
                (element) => ({
                    label: element.name,
                    value: element.id
                })
            );
        } else if (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Failed to fetch templates from Eledo",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
    }

    @wire(getObjects)
    wiredObjects({ error, data }) {
        if (data) {
            this.objects = data;
        } else if (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Failed to fetch sObjects from Salesforce",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
    }

    handleTemplateChange(event) {
        this.templateValue = event.detail.value.trim();
        this.selectedTemplate = {
            label: event.target.options.find(
                (opt) => opt.value === this.templateValue
            ).label,
            value: this.templateValue
        };
    }

    handleObjectBlur(event) {
        this.objectChoiceReportValidity(event.target);
    }

    handleObjectChange(event) {
        this.objectsValue = event.target.value.trim();
    }

    handleSOQLChange(event) {
        this.soqlValue = event.detail.value.trim();
    }

    handleCancelClick() {
        this.handleListViewNavigation();
    }

    handleSaveClick() {
        const allValid = [
            ...this.template.querySelectorAll("lightning-combobox"),
            ...this.template.querySelectorAll("input"),
            ...this.template.querySelectorAll("lightning-textarea")
        ].reduce((validSoFar, component) => {
            if (component.name === "object-choice") {
                this.objectChoiceReportValidity(component);
                return validSoFar && this.checkObjectChoiceValidity(component);
            } else {
                component.reportValidity();
                return validSoFar && component.checkValidity();
            }
        }, true);
        if (allValid) {
            this.showSpinner = true;
            this.validateSoqlAndUpsertRecord();
        }
    }

    validateSoqlAndUpsertRecord() {
        validateSoql({ query: this.soqlValue })
            .then(() => {
                this.upsertTemplate();
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Invalid SOQL.",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    upsertTemplate() {
        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.selectedTemplate.label;
        fields[TEMPLATE_ID_FIELD.fieldApiName] = this.selectedTemplate.value;
        fields[OBJECT_FIELD.fieldApiName] = this.objectsValue;
        fields[SOQL_FIELD.fieldApiName] = this.soqlValue;
        if (this.recordId) {
            this.updateExistingTemplate(fields);
        } else {
            this.createNewTemplate(fields);
        }
    }

    createNewTemplate(fields) {
        const recordInput = { apiName: TEMPLATE_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Template created.",
                        variant: "success"
                    })
                );
                this.handleListViewNavigation();
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error creating record",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    updateExistingTemplate(fields) {
        fields[ID_FIELD.fieldApiName] = this.recordId;
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Template updated.",
                        variant: "success"
                    })
                );
                this.handleListViewNavigation();
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error updating template",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    handleListViewNavigation() {
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
                objectApiName: TEMPLATE_OBJECT.objectApiName,
                actionName: "list"
            },
            state: {
                filterName: "Recent"
            }
        });
    }

    objectChoiceReportValidity(component) {
        if (!this.checkObjectChoiceValidity(component)) {
            component.setAttribute(
                "aria-describedby",
                this.template.querySelector(".object-choice-error").id
            );
            component.setAttribute("aria-invalid", "true");
            this.objectChoiceWrapperClass = "slds-form-element slds-has-error";
            this.objectChoiceErrorClass =
                "object-choice-error slds-form-element__help slds-visible";
        } else {
            component.removeAttribute("aria-describedby");
            component.removeAttribute("aria-invalid");
            this.objectChoiceWrapperClass = "slds-form-element";
            this.objectChoiceErrorClass =
                "object-choice-error slds-form-element__help slds-hidden";
        }
    }

    checkObjectChoiceValidity(component) {
        return this.objects.includes(component.value);
    }
}
