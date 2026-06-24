const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// WispByte / Railway ရဲ့ ကျန်းမာရေးစစ်ဆေးမှု (Health Check) အတွက် လမ်းကြောင်းဖွင့်ပေးခြင်း
app.get('/', (req, res) => {
  res.send('Server is running smoothly!');
});

// ရွေးချယ်နိုင်သော Health Check endpoint (တချို့ Platform တွေအတွက် လိုအပ်နိုင်တယ်)
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// ဆာဗာကို စတင်မောင်းနှင်ခြင်း (Container အတွင်း အားလုံးကနေ လက်ခံရန် 0.0.0.0)
app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Node.js Web Server is listening on port ${port}`);
});
