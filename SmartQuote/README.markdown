# Salesforce SmartQuoteCreation Deployment Instructions

Follow these steps to ensure proper setup and deployment of the Salesforce project.

## 1. Ensure the Org has Enabled RLM, Einstein, and ECI
Before proceeding with the deployment, make sure the organization has enabled the following features:
- **RLM** (Revenue Lifecycle Management)
- **Einstein** (Einstein Analytics)
- **ECI** (Einstein Call Insights)

For more details, refer to this [Quip document](https://salesforce.quip.com/MRZZA3sX4f5j).

## 2. Upload the Meeting Scripts
Upload the necessary meeting scripts to the appropriate location. You can find the required scripts in this [Quip document](https://salesforce.quip.com/reu5AfExybFy).

## 3. Download the SmartQuoteCreation Folder
Make sure to download the `SmartQuoteCreation` folder to your local environment, as this will be required for deployment.

## 4. Install Salesforce CLI
To interact with your Salesforce org, you need to install the Salesforce CLI.

Follow the installation guide here: [Salesforce CLI Installation](https://developer.salesforce.com/tools/salesforcecli).

## 5. Login to the Target Org
Log in to your Salesforce target org using the following command:
```bash
sf org login web --alias targetOrg --instance-url https://{Current My Domain URL}
```

## 6. Deploy to the Target Org
Log in to your Salesforce target org using the following command:
```bash
sf project deploy start --metadata-dir "pathToSmartQuoteCreationFolder" --target-org targetOrg
```
Replace `pathToSmartQuoteCreationFolder` with the path to the `SmartQuoteCreation` folder on your local machine.

## 7. Execute Smart Quote Creation Topic

The Topic metadata is treated as a Standard Topic. When adding the Topic to the agent, an error is returned.

### Workaround:
Manually create a new Topic with the following details:

- **Topic Label**: Smart Quote Creation New
- **Topic API Name**: Smart_Quote_Creation_New
- **Classification Description**: Interacts with the user to create a quote from the conversation transcript.

### Scope:
1. Your job is to create a quote from the conversation transcript.
2. The first agent action is **Get Video Call Records**.
3. The second agent action is **Get Products from Product Mentions**.
4. The last agent action is **Create Quote from Products**.

### Instructions:

- **Instruction 1**:  
  When a user wants to create a quote from a conversation or transcript, the agent action **Get Video Call Records** will be triggered. The input for this action is the **Opportunity ID**. If you do not know the Opportunity ID, ask the user for it. If the page context has an Opportunity, use that ID as the action input.

- **Instruction 2**:  
  The outputs of the agent action **Get Products from Product Mentions** are:
  - **ProductsOutput**: A list of Product2 records.
  - **QuoteLineItemsOutput**: A list of QuoteLineItem records.

  **QuoteLineItemsOutput** will be used as the input for the **Create Quote from Products** action.

- **Instruction 3**:  
  Afterward, the agent action **Create Quote from Products** will be triggered. The **Opportunity ID** and **QuoteLineItemsOutput** will be used as inputs for this action.

### Example User Inputs:
1. "Create quote from conversation."
2. "Create smart quote."
3. "I want to create a quote from conversation."
