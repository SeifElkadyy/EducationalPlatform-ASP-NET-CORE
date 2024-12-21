// Models/ViewModels/RegisterViewModel.cs

using System.ComponentModel.DataAnnotations;
namespace EduFinal.Models;

public class RegisterViewModel
{
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email address")]
    public string Email { get; set; }

    [Required(ErrorMessage = "Password is required")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must be at least 6 characters long")]
    [DataType(DataType.Password)]
    public string Password { get; set; }

    [Required(ErrorMessage = "Please confirm your password")]
    [DataType(DataType.Password)]
    [Compare("Password", ErrorMessage = "Passwords do not match")]
    public string ConfirmPassword { get; set; }

    [Required(ErrorMessage = "Role is required")]
    public string Role { get; set; }

    // Common fields
    [Required(ErrorMessage = "First name is required")]
    public string FirstName { get; set; }

    [Required(ErrorMessage = "Last name is required")]
    public string LastName { get; set; }

    // Optional fields
    public char? Gender { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? Country { get; set; }
    public string? CulturalBackground { get; set; }

    // Instructor-specific fields
    public string? LatestQualification { get; set; }
    public string? ExpertiseArea { get; set; }

    // Profile Image
    public IFormFile? ProfileImage { get; set; }
    public byte[] ProfileImageData { get; set; }
}