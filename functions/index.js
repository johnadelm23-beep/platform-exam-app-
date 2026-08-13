const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const TARGET_TOPIC = "all_users";

/**
 * 1. New Post Notification Trigger
 */
exports.sendPostNotification = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const postData = snap.data() || {};

    if (postData.notificationSent) {
      console.log(`Notification already sent for post ${postId}, skipping.`);
      return null;
    }

    const message = {
      notification: {
        title: "Egtma3na 📢",
        body: "بوست جديد نزل على اجتماعنا ❤️",
      },
      data: {
        type: "post",
        contentId: String(postId),
      },
      topic: TARGET_TOPIC,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent post notification for ${postId}:`, response);
      await snap.ref.update({ notificationSent: true }).catch(() => {});
      return response;
    } catch (error) {
      console.error(`Error sending post notification for ${postId}:`, error);
      return null;
    }
  });

/**
 * 2. New Exam Notification Trigger
 */
exports.sendExamNotification = functions.firestore
  .document("exams/{examId}")
  .onCreate(async (snap, context) => {
    const examId = context.params.examId;
    const examData = snap.data() || {};

    if (examData.notificationSent) {
      console.log(`Notification already sent for exam ${examId}, skipping.`);
      return null;
    }

    const message = {
      notification: {
        title: "Egtma3na 📝",
        body: "امتحان جديد مستنيك 🔥 افتح التطبيق وجرب دلوقتي",
      },
      data: {
        type: "exam",
        contentId: String(examId),
      },
      topic: TARGET_TOPIC,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent exam notification for ${examId}:`, response);
      await snap.ref.update({ notificationSent: true }).catch(() => {});
      return response;
    } catch (error) {
      console.error(`Error sending exam notification for ${examId}:`, error);
      return null;
    }
  });

/**
 * 3. Daily Content Notification Trigger
 */
exports.sendDailyContentNotification = functions.firestore
  .document("daily_content/{contentId}")
  .onCreate(async (snap, context) => {
    const contentId = context.params.contentId;
    const contentData = snap.data() || {};

    if (contentData.notificationSent) {
      console.log(`Notification already sent for daily_content ${contentId}, skipping.`);
      return null;
    }

    const message = {
      notification: {
        title: "Egtma3na ✨",
        body: "المحتوى اليومي الجديد وصل ❤️ افتح التطبيق وشوفه دلوقتي",
      },
      data: {
        type: "daily_content",
        contentId: String(contentId),
      },
      topic: TARGET_TOPIC,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent daily content notification for ${contentId}:`, response);
      await snap.ref.update({ notificationSent: true }).catch(() => {});
      return response;
    } catch (error) {
      console.error(`Error sending daily content notification for ${contentId}:`, error);
      return null;
    }
  });

/**
 * 4. New Competition Notification Trigger
 */
exports.sendCompetitionNotification = functions.firestore
  .document("competitions/{competitionId}")
  .onCreate(async (snap, context) => {
    const competitionId = context.params.competitionId;
    const competitionData = snap.data() || {};

    if (competitionData.notificationSent) {
      console.log(`Notification already sent for competition ${competitionId}, skipping.`);
      return null;
    }

    const message = {
      notification: {
        title: "Egtma3na 🏆",
        body: "مسابقة جديدة مستنياك 🔥",
      },
      data: {
        type: "competition",
        contentId: String(competitionId),
      },
      topic: TARGET_TOPIC,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent competition notification for ${competitionId}:`, response);
      await snap.ref.update({ notificationSent: true }).catch(() => {});
      return response;
    } catch (error) {
      console.error(`Error sending competition notification for ${competitionId}:`, error);
      return null;
    }
  });
