import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();

// ─── 1. Scheduled check-in monitor ───────────────────────────────────────────
// Runs every 15 min; creates missed_checkin alert + FCM when elderly skips check-in
export const scheduledCheckInMonitor = onSchedule(
  {
    schedule: "every 15 minutes",
    region: "asia-southeast1",
    timeZone: "Asia/Kuala_Lumpur",
  },
  async () => {
    // Current time in MYT (UTC+8)
    const nowMyt = new Date(Date.now() + 8 * 60 * 60 * 1000);
    const hour = nowMyt.getUTCHours();
    const inWindow = (hour >= 6 && hour < 11) || (hour >= 20 && hour < 23);
    if (!inWindow) return;

    const users = await db.collection("users")
      .where("role", "==", "elderly").get();

    for (const userDoc of users.docs) {
      const user = userDoc.data();
      const uid = userDoc.id;

      // Parse configured check-in time (default 09:00)
      const checkInTime: string = user.settings?.checkInTime ?? "09:00";
      const [h, m] = checkInTime.split(":").map(Number);
      const checkInMinutes = h * 60 + m;
      const nowMinutes = hour * 60 + nowMyt.getUTCMinutes();

      // Only alert after 30-minute grace period
      if (nowMinutes < checkInMinutes + 30) continue;

      // Check for health log today (MYT midnight)
      const todayMyt = new Date(nowMyt);
      todayMyt.setUTCHours(0, 0, 0, 0);
      const logs = await db.collection("users").doc(uid)
        .collection("healthLogs")
        .where("timestamp", ">=", todayMyt.toISOString())
        .limit(1).get();

      if (!logs.empty) continue; // Already checked in

      // Create alert
      const alertId = `missed_${uid}_${Date.now()}`;
      await db.collection("alerts").doc(alertId).set({
        id: alertId,
        type: "missed_checkin",
        elderlyUid: uid,
        elderlyName: user.name ?? "",
        message: `${user.name ?? "Pengguna"} belum check-in hari ini.`,
        severity: "medium",
        isRead: false,
        createdAt: new Date().toISOString(),
      });

      // Send FCM to care network
      const careNetwork = user.careNetwork;
      if (!careNetwork) continue;
      const contacts = [
        ...(careNetwork.caregivers ?? []),
        ...(careNetwork.buddies ?? []),
      ];
      for (const contact of contacts) {
        const token: string | undefined = contact.fcmToken;
        if (!token) continue;
        await admin.messaging().send({
          token,
          notification: {
            title: "Check-in Terlepas",
            body: `${user.name ?? "Warga emas"} belum check-in hari ini.`,
          },
        });
      }
    }
  }
);

// ─── 2. SOS handler ──────────────────────────────────────────────────────────
// Fires on new alert doc; sends high-priority FCM to all care network contacts
export const sosHandler = onDocumentCreated(
  {
    document: "alerts/{alertId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const alert = event.data?.data();
    if (!alert || alert.type !== "sos") return;

    const userDoc = await db.collection("users").doc(alert.elderlyUid).get();
    const user = userDoc.data();
    if (!user) return;

    const careNetwork = user.careNetwork;
    if (!careNetwork) return;
    const contacts = [
      ...(careNetwork.caregivers ?? []),
      ...(careNetwork.buddies ?? []),
    ];
    const tokens: string[] = contacts
      .filter((c: {fcmToken?: string}) => !!c.fcmToken)
      .map((c: {fcmToken: string}) => c.fcmToken);

    if (tokens.length === 0) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "SOS KECEMASAN!",
        body: `${alert.elderlyName ?? "Warga emas"} memerlukan bantuan segera!`,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sos_alerts",
          priority: "max",
          sound: "default",
        },
      },
    });
  }
);

// ─── 3. Weekly report generator ──────────────────────────────────────────────
// Every Sunday 8am MYT — aggregates last 7 days and writes to caregiverViews
export const weeklyReportGenerator = onSchedule(
  {
    schedule: "0 8 * * 0",
    timeZone: "Asia/Kuala_Lumpur",
    region: "asia-southeast1",
  },
  async () => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const users = await db.collection("users")
      .where("role", "==", "elderly").get();

    for (const userDoc of users.docs) {
      const uid = userDoc.id;
      const user = userDoc.data();

      const logsSnap = await db.collection("users").doc(uid)
        .collection("healthLogs")
        .where("timestamp", ">=", sevenDaysAgo.toISOString())
        .get();

      if (logsSnap.empty) continue;

      const logs = logsSnap.docs.map((d) => d.data());
      const avgMood = logs.reduce((s, l) => s + (l.mood ?? 3), 0) / logs.length;
      const avgSleep = logs.reduce((s, l) => s + (l.sleepQuality ?? 3), 0) / logs.length;
      const flagCount = logs.filter((l) => l.flags?.length > 0).length;

      const summary = {
        elderlyUid: uid,
        elderlyName: user.name ?? "",
        weekEnding: new Date().toISOString(),
        checkInCount: logs.length,
        avgMood: Math.round(avgMood * 10) / 10,
        avgSleep: Math.round(avgSleep * 10) / 10,
        flaggedDays: flagCount,
        summary: `${user.name ?? "Warga emas"} check-in ${logs.length} kali minggu ini. ` +
          `Mood purata: ${avgMood.toFixed(1)}/5, Tidur: ${avgSleep.toFixed(1)}/5.`,
        updatedAt: new Date().toISOString(),
      };

      const caregivers: Array<{uid: string}> = user.careNetwork?.caregivers ?? [];
      for (const cg of caregivers) {
        await db.collection("caregiverViews").doc(cg.uid)
          .collection("watched").doc(uid)
          .set(summary, {merge: true});
      }
    }
  }
);
