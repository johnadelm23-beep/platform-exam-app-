const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendExamNotification = functions.firestore
  .document("exams/{examId}")
  .onCreate(async (snap, context) => {
    const payload = {
      notification: {
        title: "📝 امتحان جديد",
        body: "في امتحان جديد متاح دلوقتي 👀",
      },
      topic: "all",
    };

    return admin.messaging().send(payload);
  });
exports.sendPostNotification = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const payload = {
      notification: {
        title: "📢 بوست جديد",
        body: "تم إضافة بوست جديد 🔥",
      },
      topic: "all",
    };

    return admin.messaging().send(payload);
  });
