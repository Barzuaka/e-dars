# Telegram Bot Setup Guide

## Step 1: Create a Telegram Bot

1. Open Telegram and search for "@BotFather"
2. Start a chat with BotFather
3. Send `/newbot` command
4. Follow the instructions to create your bot
5. Save the bot token (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

## Step 2: Get Your Chat ID

### Method 1: Using @userinfobot
1. Search for "@userinfobot" in Telegram
2. Start a chat with it
3. It will send you your chat ID

### Method 2: Using your bot
1. Send a message to your bot
2. Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
3. Look for the "chat" object and find the "id" field

## Step 3: Configure Environment Variables

Add these to your `.env` file:

```env
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
```

## Step 4: Test the Integration

1. Start your application
2. Run the test script: `npm run test-telegram`
3. Check your Telegram for test notifications

## Notification Types

The bot will send notifications for:

### 1. **New User Registration** 👤
- **Trigger**: When a new user registers on the site
- **Shows**: 
  - User's full name
  - Email address
  - Registration timestamp
  - User agent (browser info)

### 2. **Purchase Request** 💳
- **Trigger**: When user clicks "Sotib olish" button
- **Shows**:
  - User info (registered users) or "Guest User"
  - Phone number (if provided)
  - List of all courses in cart with prices
  - Total price
  - Timestamp

### 3. **Contact Sales Request** 📞
- **Trigger**: When user clicks "Men bilan bog'laning" in contact modal
- **Shows**:
  - Name (if provided)
  - Phone number
  - Course interest
  - Message
  - Timestamp

## What's NOT Notified

- ❌ **Cart additions** - No notifications when courses are added to cart
- ❌ **Course browsing** - No notifications for general site browsing

## Troubleshooting

- If notifications don't work, check your bot token and chat ID
- Make sure your bot is not blocked
- Check the console for error messages
- Verify your `.env` file is loaded correctly
- Test with `npm run test-telegram` to verify setup

## Example Notifications

### New User Registration:
```
👤 New User Registration

📝 Name: John Doe
📧 Email: john@example.com
📅 Registration Time: 12/15/2024, 2:30:45 PM
🌐 User Agent: Mozilla/5.0 (Windows NT 10.0...)
```

### Purchase Request:
```
💳 Purchase Request

👤 User: John Doe
📧 Email: john@example.com
📱 Phone: +998901234567

📚 Courses in Cart:
1. Blender 3D Modeling - 150,000 so'm
2. Unity Game Development - 200,000 so'm

💰 Total: 350,000 so'm
📅 Time: 12/15/2024, 2:35:20 PM
```

### Contact Sales:
```
📞 Contact Sales Request

👤 Name: John Doe
📱 Phone: +998901234567
📚 Course Interest: Blender 3D Modeling, Unity Game Development
💬 Message: Interested in purchasing 2 course(s)
📅 Time: 12/15/2024, 2:40:15 PM
``` 