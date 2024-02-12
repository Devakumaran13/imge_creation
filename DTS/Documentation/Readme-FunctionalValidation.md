<H1>About Functional-Validation</H1>
1. Create and spin VM from published image.</br>
2. Copy contents of "Execute_FunctionalValidation-DTS_VM.ps1" from "DTS/PowershellScripts/Execute_FunctionalValidation-DTS_VM.ps1" to "C:\test\Execute_FunctionalValidation-DTS_VM.ps1"</br>
3. In test VM, Open powershell command prompt in Administrator mode.</br>
4. Execute the script as follows and redirect the output to the log file.</br>
PS C:\test> .\Execute_FunctionalValidation-DTS_VM.ps1 *> "test-cycle-no-Date.log"</br>
