<H1>About Pre-Validation</H1>
1. Inputs tenant ID, client ID and subscription ID gets validated.</br>
2. Packer script contents gets validated with packer validate command.</br>
3. Fetch the list of softwares from the blob storage.</br>
4. Validate the list of softwares available in ValidationConfig.json are available in the blob storage.</br>
5. If any additional software is required to be validated, it should be added in softwares section in ValidationConfig.json.</br>
For Example:</br>
{
    "softwares": [
{
"type": "file",
"source": "Add the blob url of the software"
}
]
}
