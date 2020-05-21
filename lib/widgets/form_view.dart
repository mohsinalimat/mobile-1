import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../widgets/communication.dart';
import '../utils/helpers.dart';
import '../utils/http.dart';
import '../utils/response_models.dart';
import '../widgets/email_form.dart';
import '../widgets/view_attachments.dart';

Future<DioGetDocResponse> fetchDoc(String doctype, String name) async {
  var queryParams = {
    'doctype': doctype,
    'name': name,
  };

  final response2 = await dio.get('/method/frappe.desk.form.load.getdoc',
      queryParameters: queryParams);

  if (response2.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return DioGetDocResponse.fromJson(response2.data);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

updateDoc(String name, Map updateObj, String doctype) async {
  var response2 = await dio.put('/resource/$doctype/$name', data: updateObj);

  if (response2.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    // return IssueDetailResponse.fromJson(response2.data);
    return;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class FormView extends StatefulWidget {
  final String doctype;
  final String name;
  final Map wireframe;
  final String appBarTitle;

  FormView(
      {@required this.doctype,
      @required this.name,
      this.wireframe,
      @required this.appBarTitle});

  @override
  _FormViewState createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  Future<DioGetDocResponse> futureIssueDetail;
  bool formChanged = false;
  Map updateObj = {};
  final pageController = PageController(initialPage: 1);
  var docInfo;

  @override
  void initState() {
    super.initState();
    futureIssueDetail = fetchDoc(widget.doctype, widget.name);
  }

  void _refresh() {
    setState(() {
      futureIssueDetail = fetchDoc(widget.doctype, widget.name);
      formChanged = false;
    });
  }

  void _choiceAction(String choice) {
    if (choice == 'Attachments') {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return ViewAttachments(docInfo["attachments"]);
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          PopupMenuButton<String>(
              onSelected: _choiceAction,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'Attachments',
                    child: Text('View Attachments'),
                  )
                ];
              }),
          IconButton(
              disabledColor: Colors.white70,
              color: Colors.white,
              icon: Icon(
                Icons.save,
                // color: Colors.red,
              ),
              onPressed: formChanged
                  ? () async {
                      if (_fbKey.currentState.saveAndValidate()) {
                        var formValue = _fbKey.currentState.value;
                        await updateDoc(widget.name, formValue, widget.doctype);
                        _refresh();
                      }
                    }
                  : null)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return EmailForm(doctype: widget.doctype, doc: widget.name);
          }));
        },
        child: Icon(Icons.email),
      ),
      body: FutureBuilder(
        future: futureIssueDetail,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // processData(widget.wireframe);
            var docs = snapshot.data.values.docs;
            docInfo = snapshot.data.values.docInfo;

            return PageView(children: <Widget>[
              FormBuilder(
                key: _fbKey,
                child: GridView.count(
                    padding: EdgeInsets.all(10),
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 10.0,
                    crossAxisCount: 2,
                    children: widget.wireframe["fields"].where((field) {
                      return field["hidden"] == false &&
                          field["skip_field"] != true;
                    }).map<Widget>((field) {
                      var val = docs[0][field["fieldname"]];
                      return GridTile(
                        child: generateChildWidget(field, val, (item) {
                          setState(() {
                            docs[0][field["fieldname"]] = item;
                            formChanged = true;
                          });
                        }),
                      );
                    }).toList()),
              ),
              Communication(
                docInfo: docInfo,
                doctype: widget.doctype,
                name: widget.name,
                callback: () {
                  _refresh();
                },
              ),
            ]);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}