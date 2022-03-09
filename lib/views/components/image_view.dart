import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:photo_view/photo_view.dart';
import 'package:piwigo_ng/api/API.dart';
import 'package:piwigo_ng/constants/SettingsConstants.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:path/path.dart' as Path;

import '../VideoPlayerViewPage.dart';

class ImageView extends StatefulWidget {
  const ImageView({Key key, this.showToolBar = true, this.isAdmin = false,
    this.image, this.onZoom, this.onPanelChange}) : super(key: key);

  final bool showToolBar;
  final bool isAdmin;
  final Map<String, dynamic> image;
  final Function(bool) onZoom;
  final Function(bool) onPanelChange;

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  double _slideOffset = 0.0;
  String _derivative;

  @override
  void initState() {
    _derivative = API.prefs.getString('full_screen_image_size');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double panelHeight = 0.0;
        if(widget.showToolBar && widget.isAdmin) {
          if(MediaQuery.of(context).orientation == Orientation.portrait) {
            panelHeight = kBottomNavigationBarHeight + 40.0;
          }
        }
        return SlidingUpPanel(
          minHeight: panelHeight,
          maxHeight: constraints.maxHeight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30.0 * (1 - _slideOffset)),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          onPanelSlide: (slide) => setState(() {
            _slideOffset = slide;
          }),
          onPanelOpened: () => widget.onPanelChange(true),
          onPanelClosed: () => widget.onPanelChange(false),
          panel: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 5,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: Colors.grey.shade600
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: MediaQuery.of(context).size.width/3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(widget.image["derivatives"][_derivative]["url"],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                                padding: const EdgeInsets.all(5.0),
                                height: MediaQuery.of(context).size.width/3-30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(10.0)),
                                  color: Theme.of(context).inputDecorationTheme.fillColor,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(widget.image['file'], softWrap: true,),
                                    Text('${widget.image['width']}x${widget.image['height']} pixels'),
                                    Text(widget.image['date_available']),
                                  ],
                                )
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(widget.image['name'], style: TextStyle(
                          fontSize: 20,
                        ), softWrap: true,),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          children: [
                            imageInfoRow(
                                title: appStrings(context).editImageDetails_author,
                                content: widget.image['author'] ?? ''
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if(Path.extension(widget.image['element_url']) == '.mp4') {
                return _displayVideo(widget.image);
              }
              return _displayImage(widget.image);
            },
          ),
        );
      },
    );
  }

  Widget imageInfoRow({String title = '', String content = ''}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
          style: TextStyle(fontSize: 16),
        ),
        Expanded(
          child: Text(content,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _displayVideo(dynamic image) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: image["derivatives"][_derivative]["url"],
            fit: BoxFit.contain,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VideoPlayerViewPage(image['element_url'],
                ratio:image['width']/image['height'],
              ),
            ));
          },
          child: IconShadowWidget(
            Icon(Icons.play_arrow_rounded, size: 100, color: Color(0x80FFFFFF)),
            shadowColor: Colors.black45,
          ),
        ),
      ],
    );
  }
  Widget _displayImage(dynamic image) {
    return PhotoView(
      imageProvider: NetworkImage(image["derivatives"][_derivative]["url"]),
      minScale: PhotoViewComputedScale.contained,
      backgroundDecoration: BoxDecoration(
        color: widget.showToolBar ?
        Theme.of(context).scaffoldBackgroundColor :
        Colors.black,
      ),
      scaleStateChangedCallback: (scale) {
        widget.onZoom(scale.isScaleStateZooming);
      },
    );
  }
}
