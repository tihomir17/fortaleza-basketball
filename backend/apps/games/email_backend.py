"""
Custom email backend to handle SSL certificate issues.
"""

import ssl
import smtplib
from django.core.mail.backends.smtp import EmailBackend as SMTPEmailBackend
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class CustomSMTPEmailBackend(SMTPEmailBackend):
    """
    Custom SMTP email backend that handles SSL certificate issues.
    """

    def open(self):
        """
        Ensure an open connection to the email server.
        """
        if self.connection:
            # Nothing to do if the connection is already open.
            return False

        try:
            # Create SSL context that doesn't verify certificates
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE

            # Create SMTP connection
            if self.use_ssl:
                self.connection = smtplib.SMTP_SSL(
                    self.host, self.port, timeout=self.timeout, context=ssl_context
                )
            else:
                self.connection = smtplib.SMTP(
                    self.host, self.port, timeout=self.timeout
                )

                if self.use_tls:
                    self.connection.starttls(context=ssl_context)

            # Authenticate if credentials are provided
            if self.username and self.password:
                self.connection.login(self.username, self.password)

            logger.info(
                f"Successfully connected to SMTP server: {self.host}:{self.port}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to connect to SMTP server: {e}")
            if self.connection:
                try:
                    self.connection.quit()
                except:
                    pass
                self.connection = None
            raise


class ConsoleEmailBackend(SMTPEmailBackend):
    """
    Console email backend for development that prints emails to console.
    """

    def write_message(self, message):
        """
        Write the message to console instead of sending via SMTP.
        """
        print("\n" + "=" * 80)
        print("📧 EMAIL NOTIFICATION SENT")
        print("=" * 80)
        print(f"📬 To: {', '.join(message.to)}")
        print(f"📤 From: {message.from_email}")
        print(f"📋 Subject: {message.subject}")
        print("-" * 80)

        # Print text content
        if message.body:
            print("TEXT CONTENT:")
            print(message.body)
            print("-" * 80)

        # Print HTML content if available
        for alternative in message.alternatives:
            if alternative[1] == "text/html":
                print("HTML CONTENT:")
                print(alternative[0])
                break

        print("=" * 80)
        print("✅ Email notification sent successfully!")
        print("=" * 80 + "\n")

        return True

    def send_messages(self, email_messages):
        """
        Send messages by writing them to console.
        """
        if not email_messages:
            return 0

        sent_count = 0
        for message in email_messages:
            try:
                self.write_message(message)
                sent_count += 1
                logger.info(f"Email notification sent to console: {message.subject}")
            except Exception as e:
                logger.error(f"Failed to write email to console: {e}")

        return sent_count
