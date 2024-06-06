using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.Extensions.Logging;
using Microsoft.WindowsAzure.Storage;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace SFTPconWinSCP
{
    internal class AzureBlobStorage
    {
        ILogger log;

        private readonly BlobServiceClient _blobServiceClient;

        private string _connectionString;
        private string ConnectionString
        {
            get { return _connectionString ?? Environment.GetEnvironmentVariable("AzureWebJobsStorage"); }
            set
            {
                _connectionString = value;
                Environment.SetEnvironmentVariable("AzureWebJobsStorage", value);
            }
        }

        private string _containerName; 
        private string ContainerName
        {
            get { return _containerName ?? Environment.GetEnvironmentVariable("AzureContainerName"); }
            set
            {
                _containerName = value;
                Environment.SetEnvironmentVariable("AzureContainerName", value);
            }
        }

        public AzureBlobStorage (ILogger log)
        {
            this.log = log;

            _blobServiceClient = new BlobServiceClient(ConnectionString);
        }
        internal bool ChangeAzureConfigValues(string accountName, string accountKey,string containerName)
        {
            // Parse the connection string into a dictionary
            var parameters = ParseConnectionString(ConnectionString);

            // Modify the desired values
            parameters["AccountName"] = accountName;
            parameters["AccountKey"] = accountKey;

            // Reassemble the connection string
            string newConnectionString = BuildConnectionString(parameters);

            // Output the new connection string
            log.LogInformation(newConnectionString);
            ConnectionString = newConnectionString;
            ContainerName = containerName;
            return true;
        }

        private static Dictionary<string, string> ParseConnectionString(string connectionString)
        {
            return connectionString.Split(';')
                .Select(part => part.Split(new[] { '=' }, 2))
                .Where(part => part.Length == 2)
                .ToDictionary(sp => sp[0], sp => sp[1], StringComparer.OrdinalIgnoreCase);
        }

        private static string BuildConnectionString(Dictionary<string, string> parameters)
        {
            return string.Join(";", parameters.Select(kvp => $"{kvp.Key}={kvp.Value}"));
        }
        internal bool CheckConnection()
        {
            return Connect(ConnectionString);
        }
        private bool Connect(string connectionString)
        {
            var blobServiceClient = new BlobServiceClient(connectionString);
            var blobContainers = blobServiceClient.GetBlobContainers();
            if (blobContainers.ToList().Count != 0)
            {
                return true;
            }
            return false;
        }

        internal List<BlobItem> ListDirectoryBlobs(string directoryUrl, bool includeSubDirectories)
        {
            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(ContainerName);
            if (containerClient != null)
            {
                var blobs = containerClient.GetBlobs().ToList();
                List<BlobItem> filteredBlobs = new();
                if (includeSubDirectories)
                {
                    filteredBlobs = blobs.Where(x => x.Name.Contains(directoryUrl)).ToList();
                }
                else
                {
                    filteredBlobs = blobs.Where(x => x.Name == $"{directoryUrl}/{Path.GetFileName(x.Name)}").ToList();
                }

                return filteredBlobs;
            }
            return null;
        }

        internal async Task<Uri> UploadBlobAsync(string base64String, string fileName)
        {
            byte[] fileBytes = Convert.FromBase64String(base64String);


            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(ContainerName);

            await containerClient.CreateIfNotExistsAsync();

            BlobClient blobClient = containerClient.GetBlobClient(fileName);
            using (MemoryStream ms = new MemoryStream(fileBytes))
            {
                var blobHttpHeaders = new BlobHttpHeaders
                {
                    ContentType = GetContentType(fileName)
                };
                await blobClient.UploadAsync(ms, new BlobUploadOptions
                {
                    HttpHeaders = blobHttpHeaders
                });
            }

            return blobClient.Uri;
        }

        internal async Task<MemoryStream> GetFileBlobAsync(string blobName)
        {
            MemoryStream memoryStream = new MemoryStream();

            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(ContainerName);

            BlobClient blobClient = containerClient.GetBlobClient(blobName);
            await blobClient.DownloadToAsync(memoryStream);
            memoryStream.Position = 0; // Reset the stream position

            return memoryStream;
        }

        internal async Task<bool> DeleteBlob(string blobName)
        {
            BlobContainerClient containerClient = _blobServiceClient.GetBlobContainerClient(ContainerName);
            await containerClient.CreateIfNotExistsAsync();
            try
            {
                await containerClient.GetBlobClient(blobName).DeleteIfExistsAsync(); 
                return true;
            }
            catch (StorageException ex)
            {
                log.LogError("Error returned from the service: {0}", ex.Message);
                return false;
            }
        }
        // Determine the MIME type based on the file extension
        private string GetContentType(string fileName)
        {
            var extension = Path.GetExtension(fileName).ToLowerInvariant();
            return extension switch
            {
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                ".pdf" => "application/pdf",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                ".xls" => "application/vnd.ms-excel",
                ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                ".ppt" => "application/vnd.ms-powerpoint",
                ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                ".txt" => "text/plain",
                ".html" => "text/html",
                ".csv" => "text/csv",
                ".json" => "application/json",
                ".xml" => "application/xml",
                _ => "application/octet-stream", // Default for unknown types
            };
        }
    }
}
