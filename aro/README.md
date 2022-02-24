# Azure Red Hat OpenShift Deployment

> ***Note:*** Red Hat Open Environments will not work for deploying ARO manually due to not being able to create Resource Groups - this also does not work with the free Azure credits

## One-time Azure Account Setup

1. Create an Azure account: https://portal.azure.com/
2. Add a ***Payment Method*** in the **Cost Management + Billing** section of the Azure Portal.
3. Create a ***Subscription*** using that Payment Method - this may take up to 15 minutes for the Subscription to become available

![Subscription Creation Overview](./images/aro-subscription-view.png)

4. Open the ***Cloud Shell*** by using the button in the top bar

<img src="./images/cloud-shell-button.png" alt="Open the Cloud Shell" width="512" />

5. Make sure to use a ***Bash*** shell

<img src="./images/opened-bash-cloud-shell.png" alt="Bash shell view" width="600" />