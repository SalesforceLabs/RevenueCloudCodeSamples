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
Log in to your Salesforce target org

Go to setup -> Agent

Add Smart Quote Creation topic to default agent.
