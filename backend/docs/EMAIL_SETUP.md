# Email Setup Guide for Basketball Analytics

This guide explains how to configure email notifications for scouting reports.

## Email Configuration

### 1. Gmail Setup (Recommended for Development)

**Quick Setup Script:**
```bash
cd backend
python setup_email.py
```

**Manual Setup:**

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to: https://myaccount.google.com/security
   - Click "2-Step Verification"
   - Scroll down to "App passwords"
   - Generate a password for "Mail"
   - Copy the 16-character password

3. **Set Environment Variables**:
   ```bash
   export EMAIL_HOST_USER='your-email@gmail.com'
   export EMAIL_HOST_PASSWORD='your-16-char-app-password'
   ```

4. **Or Update Django Settings** in `basketball_analytics/settings.py`:
   ```python
   EMAIL_HOST_USER = 'your-email@gmail.com'  # Your Gmail address
   EMAIL_HOST_PASSWORD = 'your-16-char-app-password'  # App password from step 2
   ```

### 2. Development Mode (Console Backend) - CURRENT SETUP

**Currently configured for console output** - emails will be displayed in the terminal instead of being sent via SMTP.

The console backend is already active in your settings:
```python
EMAIL_BACKEND = 'apps.games.email_backend.ConsoleEmailBackend'
```

This means when you upload a scouting report, you'll see the email content in your Django server console instead of receiving actual emails.

**To switch to real email sending:**
1. Set up Gmail credentials (see section 1)
2. Change the EMAIL_BACKEND in settings.py:
   ```python
   EMAIL_BACKEND = 'apps.games.email_backend.CustomSMTPEmailBackend'
   ```

### 3. Production Setup

For production, consider using:
- **SendGrid**
- **Amazon SES**
- **Mailgun**
- **Postmark**

Update the email settings accordingly.

## Testing Email Functionality

### 1. Test with Management Command

```bash
# Test with email address
python manage.py test_email --email user@example.com

# Test with user ID
python manage.py test_email --user-id 1
```

### 2. Test with Real Upload

1. Upload a scouting report
2. Tag users with email addresses
3. Check console logs for email sending results

## Email Templates

Email templates are located in `templates/emails/`:
- `scouting_report_notification.html` - HTML version
- `scouting_report_notification.txt` - Plain text version

## Troubleshooting

### Common Issues

1. **"Authentication failed"**
   - Check your email credentials
   - Ensure 2FA is enabled and app password is correct

2. **"Connection refused"**
   - Check EMAIL_HOST and EMAIL_PORT settings
   - Ensure firewall allows SMTP connections

3. **"SSL: CERTIFICATE_VERIFY_FAILED"**
   - This is fixed by using the custom email backend
   - The custom backend disables SSL certificate verification
   - For production, consider using proper SSL certificates

4. **"No email sent"**
   - Check if users have email addresses
   - Verify EMAIL_BACKEND is not set to console
   - Check Django logs for errors

### Debug Mode

Enable debug logging in settings.py:
```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'apps.games.email_service': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
    },
}
```

## Security Notes

- Never commit email credentials to version control
- Use environment variables for production:
  ```python
  EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER')
  EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD')
  ```
- Consider using Django's `send_mail()` for simple emails
- For bulk emails, consider using Celery for background processing
