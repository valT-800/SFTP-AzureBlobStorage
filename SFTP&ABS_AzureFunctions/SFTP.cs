using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Renci.SshNet;
using Renci.SshNet.Sftp;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Linq;
using System.Text.Json.Nodes;

namespace SFTPconWinSCP
{
    class SFTP
    {
        ConnectionInfo conInfo;
        ILogger log;
        public SFTP(SFTPConnectionValues connectionValues, ILogger log)
        {
            this.log = log;
            conInfo = InitializeConnectionInfo(connectionValues);
        }
        internal static bool CheckConnection(SFTPConnectionValues connectionValues)
        {
            var con = InitializeConnectionInfo(connectionValues);
            try
            {
                using SftpClient client = new(con);
                client.Connect();
                client.Disconnect();
                return true;
            }
            catch
            {
                return false;
            }
        }
        private static ConnectionInfo InitializeConnectionInfo(SFTPConnectionValues connectionValues)
        {
            ConnectionInfo con = new(connectionValues.Address, connectionValues.Username, new PasswordAuthenticationMethod(connectionValues.Username, connectionValues.Password));
            return con;
        }
        internal string UploadFile(MemoryStream memoryStream, string sourceFileName, string path)
        {
            string targetFileName = sourceFileName;
            try
            {
                using SftpClient client = new SftpClient(conInfo);
                client.Connect();
                if (!client.Exists(path))
                {
                    client.CreateDirectory(path);
                }
                client.UploadFile(memoryStream, $"{path}/{targetFileName}");
                client.Disconnect();
                return targetFileName;
            }
            catch (Exception ex)
            {
                log.LogError(ex.Message);
                return null;
            }
        }

        internal bool DeleteFile(string sftpFilePath)
        {
            try
            {
                using var client = new SftpClient(conInfo);
                client.Connect();
                client.DeleteFile(sftpFilePath);
                client.Disconnect();
                return true;
            }
            catch(Exception ex)
            {
                log.LogError(ex.Message);
                return false;
            }
        }
        internal bool DeleteFiles(string sftpPath)
        {
            try
            {
                using var client = new SftpClient(conInfo);
                client.Connect();
                var files = client.ListDirectory(sftpPath);
                foreach (var file in files)
                {
                    client.DeleteFile($"{file.FullName}");
                }
                client.Disconnect();
                return true;
            }
            catch (Exception ex)
            {
                log.LogError(ex.Message);
                return false;
            }
        }
        internal StringCollection ListDirectory(string sftpPath, bool includeDirectories)
        {
            StringCollection filenames = new();

            using var client = new SftpClient(conInfo);
            client.Connect();
            var result = client.ListDirectory(sftpPath);
            client.Disconnect();

            foreach (var file in result)
            {
                if (includeDirectories | !file.IsDirectory)
                { filenames.Add(file.Name);}
            }
                
            return filenames;
        }
        internal List<ISftpFile> ListDirectoryFiles(string sftpPath, bool includeDirectories)
        {
            JsonArray jsonfiles = new();

            using var client = new SftpClient(conInfo);
            client.Connect();
            var files = client.ListDirectory(sftpPath);
            client.Disconnect();

            List<ISftpFile> filteredFiles = new();
            if (!includeDirectories)
            {
                filteredFiles = files.Where(file => !file.IsDirectory).ToList();
            }
            else
            {
                filteredFiles = files.ToList();
            }
            return filteredFiles;
        }
        internal string GetFileContent(string sftpFilePath)
        {
            using var client = new SftpClient(conInfo);
            client.Connect();
            var bytes = client.ReadAllBytes(sftpFilePath);
            client.Disconnect();
            string base64String = Convert.ToBase64String(bytes);
            return base64String;
        }
    }
}
