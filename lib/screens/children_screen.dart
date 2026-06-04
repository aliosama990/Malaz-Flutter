import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/child_provider.dart';
import '../models/child_mode.dart';
import 'add_child_screen.dart';
import 'child_details_screen.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ChildProvider>(
          builder: (context, childProvider, _) {
            final children = childProvider.children;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scaled(20),
                    vertical: scaled(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'اضف / اختر طفل',
                        style: GoogleFonts.cairo(
                          fontSize: scaled(20),
                          fontWeight: FontWeight.bold,
                          color: AppColors.registerTitle,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_forward,
                            color: AppColors.registerTitle,
                            size: scaled(28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: scaled(20)),
                Expanded(
                  child: children.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد أطفال مسجلين',
                            style: GoogleFonts.cairo(
                              fontSize: scaled(16),
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: scaled(24)),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: scaled(16),
                              runSpacing: scaled(16),
                              children: children
                                  .map((child) =>
                                      _buildChildCard(context, child))
                                  .toList(),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(scaled(20)),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddChildScreen(canSkip: false),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: scaled(16)),
                      decoration: BoxDecoration(
                        color: AppColors.registerTitle,
                        borderRadius: BorderRadius.circular(scaled(30)),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.registerTitle.withValues(alpha: 0.3),
                            blurRadius: scaled(10),
                            offset: Offset(0, scaled(4)),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'اضافة طفل اخر',
                            style: GoogleFonts.cairo(
                              fontSize: scaled(16),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: scaled(8)),
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: scaled(22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildModel child) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final cardWidth = (MediaQuery.of(context).size.width - scaled(64)) / 2;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailsScreen(child: child),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardWidth / 1.4,
        decoration: BoxDecoration(
          color: AppColors.registerTitle,
          borderRadius: BorderRadius.circular(scaled(16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.registerTitle.withValues(alpha: 0.25),
              blurRadius: scaled(8),
              offset: Offset(0, scaled(4)),
            ),
          ],
        ),
        child: Center(
          child: Text(
            child.name,
            style: GoogleFonts.cairo(
              fontSize: scaled(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
