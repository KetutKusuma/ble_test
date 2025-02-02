import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class CobaTest extends StatefulWidget {
  const CobaTest({super.key});

  @override
  State<CobaTest> createState() => _CobaTestState();
}

class _CobaTestState extends State<CobaTest> {
  PagingController<dynamic, dynamic> pagingCon =
      PagingController(firstPageKey: 1);
  @override
  Widget build(BuildContext context) {
    return PagedMasonryGridView(
      pagingController: pagingCon,
      builderDelegate: PagedChildBuilderDelegate(
        itemBuilder: (context, item, index) => Container(),
      ),
      gridDelegateBuilder: (index) =>
          SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }
}
