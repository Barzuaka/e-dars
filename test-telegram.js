import dotenv from 'dotenv';
import telegramService from './services/telegramService.js';

// Load environment variables
dotenv.config();

async function testTelegramIntegration() {
  console.log('Testing Telegram Bot Integration...\n');
  
  // Check if environment variables are loaded
  console.log('Environment Check:');
  console.log('TELEGRAM_BOT_TOKEN:', process.env.TELEGRAM_BOT_TOKEN ? '✅ Set' : '❌ Not set');
  console.log('TELEGRAM_CHAT_ID:', process.env.TELEGRAM_CHAT_ID ? '✅ Set' : '❌ Not set');
  console.log('');
  
  if (!process.env.TELEGRAM_BOT_TOKEN || !process.env.TELEGRAM_CHAT_ID) {
    console.log('❌ Environment variables not loaded properly!');
    console.log('Please check your .env file and make sure it contains:');
    console.log('TELEGRAM_BOT_TOKEN=your_bot_token_here');
    console.log('TELEGRAM_CHAT_ID=your_chat_id_here');
    return;
  }
  
  // Test 1: Simple message
  console.log('1. Testing simple message...');
  const simpleResult = await telegramService.sendMessage('🧪 Test message from course platform');
  console.log('Simple message result:', simpleResult ? '✅ Success' : '❌ Failed');
  
  // Test 2: New user registration notification
  console.log('\n2. Testing new user registration notification...');
  const userInfo = {
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  };
  const registrationResult = await telegramService.sendNewUserNotification(userInfo);
  console.log('Registration notification result:', registrationResult ? '✅ Success' : '❌ Failed');
  
  // Test 3: Purchase notification
  console.log('\n3. Testing purchase notification...');
  const cartItems = [
    { title: 'Blender 3D Modeling', price: 150000 },
    { title: 'Unity Game Development', price: 200000 }
  ];
  const purchaseResult = await telegramService.sendPurchaseNotification(cartItems, userInfo, '+998901234567');
  console.log('Purchase notification result:', purchaseResult ? '✅ Success' : '❌ Failed');
  
  // Test 4: Contact sales notification
  console.log('\n4. Testing contact sales notification...');
  const contactData = {
    name: 'Test User',
    phone: '+998901234567',
    course: 'Blender 3D Modeling, Unity Game Development',
    message: 'Interested in purchasing 2 course(s)'
  };
  const contactResult = await telegramService.sendContactSalesNotification(contactData);
  console.log('Contact sales notification result:', contactResult ? '✅ Success' : '❌ Failed');
  
  // Test 5: Guest user purchase notification
  console.log('\n5. Testing guest user purchase notification...');
  const guestPurchaseResult = await telegramService.sendPurchaseNotification(cartItems, null, '+998901234567');
  console.log('Guest purchase notification result:', guestPurchaseResult ? '✅ Success' : '❌ Failed');
  
  console.log('\n🎉 Telegram integration test completed!');
  console.log('\nIf all tests passed, your bot is working correctly.');
  console.log('Check your Telegram for the test messages.');
  console.log('\n📋 Notification Summary:');
  console.log('- ✅ New user registrations');
  console.log('- ✅ Purchase requests (registered & guest users)');
  console.log('- ✅ Contact sales requests');
  console.log('- ❌ Cart additions (removed as requested)');
}

// Run the test
testTelegramIntegration().catch(error => {
  console.error('Test failed:', error);
}); 