const express = require('express');
const { exec } = require('child_process');
const app = express();
const port = process.env.PORT || 3000;

// WispByte ရဲ့ ကျန်းမာရေးစစ်ဆေးမှု (Health Check) အတွက် လမ်းကြောင်းဖွင့်ပေးခြင်း
app.get('/', (req, res) => {
  res.send('Server is running smoothly!');
});

app.listen(port, () => {
  console.log(`Node.js Web Server is listening on port ${port}`);

  // နောက်ကွယ်တွင် 3X-UI အား အလိုအလျောက် စတင်မောင်းနှင်ရန် ကုဒ်
  // အစ်ကိုကြီး WispByte ထဲထည့်မည့် Script သို့မဟုတ် Binary လမ်းကြောင်းအတိုင်း ၎င်းနေရာတွင် လှမ်းခေါ်ပေးရပါမည်
  exec('./x-ui', (err, stdout, stderr) => {
    if (err) {
      console.error(`Error starting 3X-UI: ${err.message}`);
      return;
    }
    if (stderr) {
      console.error(`3X-UI Stderr: ${stderr}`);
      return;
    }
    console.log(`3X-UI Stdout: ${stdout}`);
  });
});

