import axios from 'axios';

class TelegramService {
  constructor() {
    // Don't load environment variables in constructor
  }

  // Get bot configuration dynamically
  getBotConfig() {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    
    if (!botToken || !chatId) {
      console.warn('Telegram bot token or chat ID not configured');
      return null;
    }
    
    return {
      botToken,
      chatId,
      baseUrl: `https://api.telegram.org/bot${botToken}`
    };
  }

  // Send a simple text message
  async sendMessage(message) {
    try {
      const config = this.getBotConfig();
      if (!config) {
        return false;
      }

      const response = await axios.post(`${config.baseUrl}/sendMessage`, {
        chat_id: config.chatId,
        text: message,
        parse_mode: 'HTML'
      });

      return response.data.ok;
    } catch (error) {
      console.error('Error sending Telegram message:', error.message);
      return false;
    }
  }

  // Send new user registration notification
  async sendNewUserNotification(userInfo) {
    let message = '👤 <b>New User Registration</b>\n\n';
    message += `📝 <b>Name:</b> ${userInfo.firstName} ${userInfo.lastName}\n`;
    message += `📧 <b>Email:</b> ${userInfo.email}\n`;
    message += `📅 <b>Registration Time:</b> ${new Date().toLocaleString('ru-RU')}\n`;
    message += `🌐 <b>User Agent:</b> ${userInfo.userAgent || 'Not available'}\n`;
    
    return await this.sendMessage(message);
  }

  // Send purchase notification when user clicks "Sotib olish"
  async sendPurchaseNotification(cartItems, userInfo = null, phoneNumber = null) {
    let message = '💳 <b>Purchase Request</b>\n\n';
    
    if (userInfo) {
      message += `👤 <b>User:</b> ${userInfo.firstName} ${userInfo.lastName}\n`;
      message += `📧 <b>Email:</b> ${userInfo.email}\n`;
    } else {
      message += `👤 <b>User:</b> Guest User\n`;
    }
    
    if (phoneNumber) {
      message += `📱 <b>Phone:</b> ${phoneNumber}\n`;
    }
    
    message += `\n📚 <b>Courses in Cart:</b>\n`;
    
    let totalPrice = 0;
    cartItems.forEach((item, index) => {
      message += `${index + 1}. ${item.title} - ${item.price.toLocaleString('ru-RU')} so'm\n`;
      totalPrice += item.price;
    });
    
    message += `\n💰 <b>Total:</b> ${totalPrice.toLocaleString('ru-RU')} so'm\n`;
    message += `📅 <b>Time:</b> ${new Date().toLocaleString('ru-RU')}\n`;
    
    return await this.sendMessage(message);
  }

  // Send contact sales notification when user clicks "Men bilan bog'laning"
  async sendContactSalesNotification(contactData) {
    let message = '📞 <b>Contact Sales Request</b>\n\n';
    
    if (contactData.name) {
      message += `👤 <b>Name:</b> ${contactData.name}\n`;
    }
    
    if (contactData.phone) {
      message += `📱 <b>Phone:</b> ${contactData.phone}\n`;
    }
    
    if (contactData.course) {
      message += `📚 <b>Course Interest:</b> ${contactData.course}\n`;
    }
    
    if (contactData.message) {
      message += `💬 <b>Message:</b> ${contactData.message}\n`;
    }
    
    message += `📅 <b>Time:</b> ${new Date().toLocaleString('ru-RU')}\n`;
    
    return await this.sendMessage(message);
  }
}

export default new TelegramService(); 