import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memorare/components/loading_animation.dart';
import 'package:memorare/components/web/discover_card.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/types/author.dart';
import 'package:memorare/types/reference.dart';

List<Reference> _references = [];
List<Author> _authors = [];

class Discover extends StatefulWidget {
  @override
  _DiscoverState createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  String lang = 'en';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (_authors.length > 0 || _references.length > 0) {
      return;
    }

    fetchAuthorsAndReferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          if (isLoading) {
            return LoadingAnimation(
              textTitle: 'Loading Discover section...',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await fetchAuthorsAndReferences();
              return null;
            },
            child: ListView(
              padding: EdgeInsets.only(
                top: 50.0,
                bottom: 200.0,
              ),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Discover',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Opacity(
                    opacity: .6,
                    child: Text(
                      'Uncover new authors and references.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  )
                ),

                Divider(height: 60.0,),

                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.center,
                  children: cardsList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> cardsList() {
    List<Widget> cards = [];
    double index = 0;

    for (var reference in _references) {
      cards.add(
        FadeInY(
          delay: index,
          beginY: 100.0,
          child: DiscoverCard(
            elevation: 5.0,
            height: 240.0,
            id: reference.id,
            imageUrl: reference.urls.image,
            name: reference.name,
            summary: reference.summary,
            textHeight: 60.0,
            titleFontSize: 15.0,
            type: 'reference',
            width: 170.0,
          ),
        )
      );

      index += 1.0;
    }

    for (var author in _authors) {
      cards.add(
        FadeInY(
          delay: index,
          beginY: 100.0,
          child: DiscoverCard(
            elevation: 5.0,
            height: 220.0,
            id: author.id,
            imageUrl: author.urls.image,
            name: author.name,
            summary: author.summary,
            textHeight: 60.0,
            titleFontSize: 15.0,
            type: 'author',
            width: 170.0,
          ),
        )
      );

      index += 1.0;
    }

    return cards;
  }

  Future fetchAuthorsAndReferences() async {
    _authors.clear();
    _references.clear();

    setState(() {
      isLoading = true;
    });

    try {
      final refsSnapshot = await Firestore.instance
        .collection('references')
        .orderBy('updatedAt', descending: true)
        .limit(2)
        .getDocuments();

      if (refsSnapshot.documents.isNotEmpty) {
        refsSnapshot.documents.forEach((doc) {
          final data = doc.data;
          data['id'] = doc.documentID;

          final ref = Reference.fromJSON(data);
          _references.add(ref);
        });
      }

      final authorsSnapshot = await Firestore.instance
        .collection('authors')
        .orderBy('updatedAt', descending: true)
        .limit(4)
        .getDocuments();

      final snapDocs = authorsSnapshot.documents.sublist(0);

      if (snapDocs.isNotEmpty) {
        snapDocs
          .removeWhere((element) {
            return _references.any((ref) {
              return ref.name == element.data['name'];
            });
          });

        snapDocs.take(2).forEach((doc) {
          final data = doc.data;
          data['id'] = doc.documentID;

          final author = Author.fromJSON(data);
          _authors.add(author);
        });
      }

      if (!this.mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

    } catch (error, stackTrace) {
      debugPrint('error => $error');
      debugPrint(stackTrace.toString());

      setState(() {
        isLoading = false;
      });
    }
  }
}
