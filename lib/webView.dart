import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';


class webView extends StatefulWidget {
  const webView({Key? key}) : super(key: key);

  @override
  State<webView> createState() => _webViewState();
}

class _webViewState extends State<webView> {
  late InAppWebViewController inAppWebViewController;
  double _progress = 0;
  String url = "";
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));
  late PullToRefreshController pullToRefreshController;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          inAppWebViewController?.reload();
        } else if (Platform.isIOS) {
          inAppWebViewController?.loadUrl(
              urlRequest: URLRequest(url: await inAppWebViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse("https://www.pathchola.com")),
                  initialOptions: options,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (InAppWebViewController controller){
                      inAppWebViewController = controller;
                    },
                  onLoadStart: (controller, url){

                    },
                  onProgressChanged: (InAppWebViewController controller, int progress){
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                  androidOnPermissionRequest: (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;
                    var urllaunchable = await canLaunch(uri as String); //canLaunch is from url_launcher package
                    if(urllaunchable){
                    await launch(uri as String); //launch is from url_launcher package to launch URL
                    }else{
                    print("URL can't be launched.");
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
                _progress < 1 ? SizedBox(height: 3, child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.lightGreen.withOpacity(0.2),
                ),) : const SizedBox(),
              ],
            ),
          ),
        ),
        onWillPop: () => _goBack(context));
  }

  Future<bool> _goBack(BuildContext context) async {
    if (await inAppWebViewController.canGoBack()) {
      inAppWebViewController.goBack();
      return Future.value(false);
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Do you want to exit'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: Text('Yes'),
              ),
            ],
          ));
      return Future.value(true);
    }
  }
}

