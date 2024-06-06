using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;
using Microsoft.AspNetCore.Routing;

namespace SFTPconWinSCP
{
    public static class AzureFunctions
    {

        [FunctionName("SFTPInitializeConnection")]
        public static async Task<IActionResult> SFTPInitializeConnection(
        [HttpTrigger(AuthorizationLevel.Function, "put", Route = null)] HttpRequest req, ILogger log)
        {
            //Deserialize send parameters
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            string sftpAddress = data.address;
            string sftpPort = data.port;
            string sftpUsername = data.username;
            string sftpPassword = data.password;

            //Change SFTP connection values
            SFTPConnectionValues sftpConnectionValues = new(sftpAddress, sftpPort, sftpUsername, sftpPassword);
            //Try to connect with new connection values
            var connected = SFTP.CheckConnection(sftpConnectionValues);

            return connected
                ? (ActionResult)new OkObjectResult($"Connection values sucessfully saved")
                : new BadRequestObjectResult("Error on input parameter");
        }
        [FunctionName("SFTPCheckConnection")]
        public static IActionResult SFTPCheckConnection(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req, ILogger log)
        {
            //Try to connect with current connection values
            SFTPConnectionValues sftpConnValues = new();
            var connected = SFTP.CheckConnection(sftpConnValues);

            return connected
                ? (ActionResult)new OkObjectResult($"Connected sucessfully")
                : new BadRequestObjectResult("Error on input parameter");
        }
        [FunctionName("AzureChangeConfigValues")]
        public static async Task<IActionResult> AzureChangeConfigValues(
        [HttpTrigger(AuthorizationLevel.Function, "put", Route = null)] HttpRequest req, ILogger log)
        {
            //Deserialize send parameters
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            string accountName = data.accountName;
            string accountKey = data.accountKey;
            string containerName = data.containerName;

            //Connect to Azure with new configuration values
            AzureBlobStorage azureBlobStorage = new(log);
            var changed = azureBlobStorage.ChangeAzureConfigValues(accountName, accountKey, containerName);

            return changed
                ? (ActionResult)new OkObjectResult($"Azure storage connection values sucessfully saved")
                : new BadRequestObjectResult("Error on input parameter");
        }

        [FunctionName("SFTPUploadFileFromAzure")]
        public static async Task<IActionResult> UploadFileFromAzure(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, ILogger log)
        {
            //Deserialize send parameters
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            string filePath = data.azureFilePath;
            string sftpPath = data.sftpPath;
            string targetFileName;

            string fileName = Path.GetFileName(filePath);

            //Get memory stream from Azure Blob Storage
            AzureBlobStorage azureBlobStorage = new(log);
            var memoryStream = await azureBlobStorage.GetFileBlobAsync(filePath);

            //Upload to SFTP from memory stream
            SFTPConnectionValues sftpConnValues = new();
            SFTP sftp = new(sftpConnValues, log);
            targetFileName = sftp.UploadFile(memoryStream, fileName, sftpPath);

            return targetFileName != null
                ? (ActionResult)new OkObjectResult($"File {targetFileName} stored.")
                : new BadRequestObjectResult("Error on input parameter");
        }
        [FunctionName("SFTPCopyDirectoryFromAzure")]
        public static async Task<IActionResult> SFTPCopyDirectoryFromAzure(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, ILogger log)
        {
            //Deserialize send parameters
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            string azurePath = data.azurePath;
            string sftpPath = data.sftpPath;
            bool includeSubDirectories = data.includeSubDirectories;
       
            //Get list of BlobItem
            AzureBlobStorage azureBlobStorage = new(log);
            var blobs = azureBlobStorage.ListDirectoryBlobs(azurePath,includeSubDirectories);

            SFTPConnectionValues sftpConnValues = new();
            SFTP sftp = new(sftpConnValues, log);
            try
            {
                //Go through all files, get blob file memory stream and upload to SFTP
                foreach ( var blob in blobs )
                {
            
                    var memoryStream = await azureBlobStorage.GetFileBlobAsync(blob.Name);
                    var blobName = Path.GetFileName(blob.Name);
                    var path = Path.Combine(sftpPath, Path.GetDirectoryName(blob.Name));
                    path = path.Replace('\\', '/');
                    sftp.UploadFile(memoryStream, blobName, path);
                }

                return new OkObjectResult($"Azure directory copied");
            }
            catch {
                return new BadRequestObjectResult("Error on input parameter"); 
            }
        }

        [FunctionName("SFTPListDirectory")]
        public static async Task<IActionResult> ListDirectory(
       [HttpTrigger(AuthorizationLevel.Function, "get", Route = "ListDirectory")]
        HttpRequest req, ILogger log)
        {
            string sftpPath = req.Query["sftpPath"];
            bool includeDir = req.Query["includeDirectories"] == "No" ? false : true;

            //Get SFTP file names of requested directory
            SFTPConnectionValues sftpConnectionValues = new();
            SFTP sftp = new(sftpConnectionValues, log);
            var filenames = sftp.ListDirectory(sftpPath, includeDir);

            //Serialize file names list to json format
            var jsonResult = JsonConvert.SerializeObject(filenames);

            return jsonResult != null
                ? (ActionResult)new OkObjectResult(jsonResult)
                : new BadRequestObjectResult("Error on input parameter");
        }

        [FunctionName("SFTPListDirectoryFiles")]
        public static async Task<IActionResult> ListDirectoryFiles(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "SFTPListDirectoryFiles")]
        HttpRequest req, ILogger log)
        {
            string sftpPath = req.Query["sftpPath"];
            bool includeDir = req.Query["includeDirectories"] == "No" ? false : true;

            //List SFTP directory files 
            SFTPConnectionValues sftpConfigurationValues = new();
            SFTP sftp = new(sftpConfigurationValues, log);
            var files = sftp.ListDirectoryFiles(sftpPath, includeDir);

            //Serialize List of ISftpFile json format
            var jsonResult = JsonConvert.SerializeObject(files);

            return jsonResult != null
                ? (ActionResult)new OkObjectResult(jsonResult)
                : new BadRequestObjectResult("Error on input parameter");
        }

        [FunctionName("SFTPDownloadFilesToAzure")]
        public static async Task<IActionResult> DownloadFilesToAzure(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]
        HttpRequest req, ILogger log)
        {
            try
            {
                //Deserialize send parameters
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                dynamic data = JsonConvert.DeserializeObject(requestBody);
                string sftpPath = data.sftpPath;
                string azurePath = data.azurePath;
                bool remove = data.remove;

                //Get list of ISftpFile
                SFTPConnectionValues sftpConfigurationValues = new();
                SFTP sftp = new(sftpConfigurationValues, log);
                var files = sftp.ListDirectoryFiles(sftpPath, false);

                //Go through all files, get file content, upload it to Azure Blob Storage and delete from SFTP if needed
                AzureBlobStorage azureBlobStorage = new(log);
                foreach (var file in files)
                {
                    var base64String = sftp.GetFileContent(file.FullName);
                    Uri uri = await azureBlobStorage.UploadBlobAsync(base64String, azurePath + file.Name);
                    if (uri !=null && remove)
                    {
                        sftp.DeleteFile(file.FullName);
                    }
                }
                return new OkObjectResult($"Files downloaded to {azurePath} stored.");
            }
            catch (Exception ex)
            {
                log.LogError($"Error downloading files: {ex.Message}");
                return new StatusCodeResult((int)HttpStatusCode.InternalServerError);
            }
        }

        [FunctionName("SFTPDownloadFileToAzure")]
        public static async Task<IActionResult> DownloadFile(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)]
        HttpRequest req, ILogger log)
        {
            try
            {
                //Deserialize send parameters
                string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                dynamic data = JsonConvert.DeserializeObject(requestBody);
                string sftpFilePath = data.sftpFilePath;
                string azurePath = data.azurePath;
                bool remove = data.remove;

                string blobName = Path.GetFileName(sftpFilePath);

                //Get SFTP file content
                SFTPConnectionValues sftpConfigurationValues = new();
                SFTP sftp = new(sftpConfigurationValues, log);
                var base64String = sftp.GetFileContent(sftpFilePath);

                //Upload SFTP file content to Azure Blob Storage and delete if needed
                AzureBlobStorage azureBlobStorage = new(log);
                Uri uri = await azureBlobStorage.UploadBlobAsync(base64String, azurePath + blobName);
                if ( uri !=null && remove ) {
                    sftp.DeleteFile(sftpFilePath);
                }
                return uri !=null
                    ? (ActionResult)new OkObjectResult($"File downloaded")
                    : new BadRequestObjectResult("Error on input parameter");
            }
            catch (Exception ex)
            {
                log.LogError($"Error downloading files: {ex.Message}");
                return new StatusCodeResult((int)HttpStatusCode.InternalServerError);
            }
        }

        [FunctionName("SFTPDeleteFile")]
        public static async Task<IActionResult> DeleteFile(
        [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "SFTPDeleteFile")]
        HttpRequest req, ILogger log)
        {
            string sftpFilePath = req.Query["sftpFilePath"];
            SFTPConnectionValues sftpConfigurationValues = new();
            SFTP sftp = new(sftpConfigurationValues, log);
            bool deleted = sftp.DeleteFile(sftpFilePath);

            return deleted
                ? (ActionResult)new OkObjectResult($"File {sftpFilePath} successfully removed!")
                : new BadRequestObjectResult("Error on input parameter");
        }
        [FunctionName("SFTPDeleteFiles")]
        public static async Task<IActionResult> DeleteFiles(
        [HttpTrigger(AuthorizationLevel.Function, "delete", Route = "SFTPDeleteFiles")]
        HttpRequest req, ILogger log)
        {
            string sftpPath = req.Query["sftpPath"];
            SFTPConnectionValues sftpConfigurationValues = new();
            SFTP sftp = new(sftpConfigurationValues, log);
            bool deleted = sftp.DeleteFiles(sftpPath);

            return deleted
                ? (ActionResult)new OkObjectResult($"Files successfully removed!")
                : new BadRequestObjectResult("Error on input parameter");
        }
    }
}
