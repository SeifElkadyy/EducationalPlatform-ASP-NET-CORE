﻿// Models/Domain/User.cs

namespace EduFinal.Models.Domain
{
    public class User
    {
        public int UserID { get; set; }
        public string Email { get; set; }
        public string PasswordHash { get; set; }
        public string Role { get; set; }
        public byte[]? ProfileImage { get; set; }
        public DateTime CreationDate { get; set; }
        public bool IsActive { get; set; }
    }
}