import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ntu_library_companion/model/category.dart';
import 'package:ntu_library_companion/widgets/text_outline.dart';

class CategoryCard extends StatelessWidget {
  final Category cat;
  final Function(String cateId) tapCallback;

  const CategoryCard({super.key, required this.cat, required this.tapCallback});

  @override
  Widget build(BuildContext context) {
    ColorScheme c = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () {
          tapCallback(cat.catId);
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cat.attachmentId != "")
                CachedNetworkImage(
                  imageUrl:
                      "https://sms.lib.ntu.edu.tw/rest/council/common/resourceCates/${cat.catId}/attachs/${cat.attachmentId}/file",
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 8),
              Text(
                cat.engName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(cat.description),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Stack(
                      children: [
                        LinearProgressIndicator(
                          minHeight: 20,
                          borderRadius: BorderRadius.circular(10),
                          value: cat.available / cat.capacity,
                          color: c.tertiary.withAlpha(100),
                          backgroundColor: c.tertiaryContainer.withAlpha(100),
                          semanticsLabel: 'Available',
                          semanticsValue:
                              'Available: ${cat.available} of ${cat.capacity}',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: OutlineText(
                                    child: Text(
                                      "Available:",
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              OutlineText(
                                child: Text(
                                  softWrap: false,
                                  "${cat.available} / ${cat.capacity}",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.location_city,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            cat.branch.enName,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
