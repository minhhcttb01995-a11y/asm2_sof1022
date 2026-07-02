using System.ComponentModel.DataAnnotations;

namespace JobConnect.Models;

public class Message
{
    [Key]
    public int MessageID { get; set; }
    
    public int SenderID { get; set; }
    public User? Sender { get; set; }
    
    public int ReceiverID { get; set; }
    public User? Receiver { get; set; }
    
    public string Content { get; set; } = string.Empty;
    
    public bool IsRead { get; set; } = false;
    
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    
    // Optional: Reference to a job if the chat is about a specific job
    public int? JobID { get; set; }
    public JobPost? Job { get; set; }
}
