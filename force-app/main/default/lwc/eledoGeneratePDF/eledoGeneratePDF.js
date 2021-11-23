import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import TEMPLATE_OBJECT from "@salesforce/schema/Eledo_Template__c";
import findTemplates from "@salesforce/apex/EledoGeneratePDFController.findTemplates";
import generatePDF from "@salesforce/apex/EledoAPI.generatePDF";

export default class EledoGeneratePDF extends LightningElement {
    @api recordId;
    @api sObjectName;
    sfTemplates = [];
    value = "";
    showSpinner = false;
    fieldsInfo;
    buttonDisabled = false;

    @wire(getObjectInfo, { objectApiName: TEMPLATE_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.fieldsInfo = data.fields;
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

    @wire(findTemplates, { sObjectName: "$sObjectName" })
    wiredTemplates({ error, data }) {
        this.showSpinner = true;
        if (data) {
            this.sfTemplates = data.map((element) => ({
                label: element.Name,
                value: element.Name
            }));
            if (this.sfTemplates.length > 0) {
                this.value = this.sfTemplates[0].value;
            } else {
                this.buttonDisabled = true;
            }
        } else if (error) {
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Failed to retrieve templates from Salesforce",
                    message: error.body.message,
                    variant: "error"
                })
            );
        }
        this.showSpinner = false;
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleClick() {
        this.showSpinner = true;
        generatePDF({
            recordId: this.recordId,
            templateName: this.value
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "PDF was saved into attachments.",
                        variant: "success"
                    })
                );
                //refresh the whole page, so we can get the record into a related attachment list
                this.dispatchEvent(new CustomEvent("recordChange"));
            })
            .catch((error) => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Failed to generate PDF",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }
}
