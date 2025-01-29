import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reminder_app/services/notification_logic.dart';
import 'package:reminder_app/utils/app_colors.dart';
import 'package:reminder_app/widgets/add_reminder.dart';
import 'package:reminder_app/widgets/delete_reminder.dart';
import 'package:reminder_app/widgets/switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  User? user;
  bool on = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    NotificationLogic.init(context, user!.uid);
    listenNotifications();
  }

  void listenNotifications() {
    NotificationLogic.onNotifications.listen((value) {});
  }

  void onClickedNotifications(String? payload) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          backgroundColor: AppColors.whiteColor,
          centerTitle: true,
          elevation: 0,
          title: Text(
            "Reminder App",
            style: TextStyle(
                color: AppColors.blackColor,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            AddReminder(context, user!.uid);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryG,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .collection("reminder")
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FA8C5)),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text("No Reminders"),
              );
            }

            final data = snapshot.data;

            return ListView.builder(
              itemCount: data?.docs.length,
              itemBuilder: (context, index) {
                Timestamp t = data?.docs[index].get("time");
                DateTime date = DateTime.fromMicrosecondsSinceEpoch(
                    t.microsecondsSinceEpoch);
                String formattedTime = DateFormat.jm().format(date);
                on = data!.docs[index].get("onOff");

                if (on) {
                  NotificationLogic.showNotifications(
                      dateTime: date,
                      id: 0,
                      title: "Reminder",
                      body: "Dont fro");
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              formattedTime,
                              style: TextStyle(fontSize: 30),
                            ),
                            subtitle: Text("Everyday"),
                            trailing: Container(
                              width: 110,
                              child: Row(
                                children: [
                                  Switcher(on, user!.uid, data.docs[index].id,
                                      data.docs[index].get("time")),
                                  IconButton(
                                      onPressed: () {
                                        deleteReminder(context,
                                            data.docs[index].id, user!.uid);
                                      },
                                      icon: Icon(Icons.delete)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
