using System;

namespace SFTPconWinSCP
{
    internal class SFTPConnectionValues
    {
        internal string Address { get; set; }
        internal string Port { get; set; }
        internal string Username { get; set; }
        public string Password { get; set; }
        public SFTPConnectionValues(string address, string port, string username, string password)
        {
            Address = address;
            Port = port;
            Username = username;
            Password = password;
            SetEnvironmentVariables(address, port, username, password);
        }
        public SFTPConnectionValues()
        {
            GetEnvironmentVariables();
        }
        private void GetEnvironmentVariables()
        {
            Address = Environment.GetEnvironmentVariable("SftpAddress");
            Port = Environment.GetEnvironmentVariable("SftpPort");
            Username = Environment.GetEnvironmentVariable("SftpUsername");
            Password = Environment.GetEnvironmentVariable("SftpPassword");
        }
        private void SetEnvironmentVariables(string address, string port, string username, string password)
        {
            Environment.SetEnvironmentVariable("SftpAddress", address);
            Environment.SetEnvironmentVariable("SftpPort", port);
            Environment.SetEnvironmentVariable("SftpUsername",username);
            Environment.SetEnvironmentVariable ("SftpPassword",password);
        }
    }
}
