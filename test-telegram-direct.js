import axios from 'axios';

// Test with your actual values
const BOT_TOKEN = '7892329409:AAHIF39yUZpRYI2lBCutRAEoySqu7EtNXXA';
const CHAT_ID = '32027481';

async function testTelegramDirect() {
  console.log('Testing Telegram API directly...');
  console.log('Bot Token:', BOT_TOKEN.substring(0, 10) + '...');
  console.log('Chat ID:', CHAT_ID);
  
  try {
    const response = await axios.post(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
      chat_id: CHAT_ID,
      text: '🧪 Test message from course platform - Direct API call',
      parse_mode: 'HTML'
    });
    
    console.log('✅ Success!');
    console.log('Response:', response.data);
    
    if (response.data.ok) {
      console.log('Message sent successfully!');
    } else {
      console.log('❌ API returned error:', response.data);
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
    if (error.response) {
      console.log('Error response:', error.response.data);
    }
  }
}

testTelegramDirect(); 