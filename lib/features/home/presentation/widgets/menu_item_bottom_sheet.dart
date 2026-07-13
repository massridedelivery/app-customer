import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/domain/models/food_models.dart';
import 'package:flutter/material.dart';

class MenuItemBottomSheet extends StatefulWidget {
  final MenuItemModel item;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final void Function(
    int quantity,
    double totalPrice,
    List<ModifierModel> selectedModifiers,
    String notes,
  )?
  onAddToCart;

  const MenuItemBottomSheet({
    super.key,
    required this.item,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    this.onAddToCart,
  });

  @override
  State<MenuItemBottomSheet> createState() => _MenuItemBottomSheetState();
}

class _MenuItemBottomSheetState extends State<MenuItemBottomSheet> {
  int _quantity = 1;
  final Map<String, String> _selectedRadioModifiers = {};
  final Map<String, Set<String>> _selectedMultiModifiers = {};
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDefaultSelections();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _initDefaultSelections() {
    for (final group in widget.item.modifierGroups) {
      if (!group.isActive) continue;
      if (group.maxSelect == 1 && group.minSelect == 1) {
        final available =
            group.modifiers.where((m) => m.isAvailable).toList();
        if (available.isNotEmpty) {
          _selectedRadioModifiers[group.id] = available.first.id;
        }
      }
    }
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  List<ModifierModel> _getSelectedModifiers() {
    final List<ModifierModel> selected = [];
    for (final group in widget.item.modifierGroups) {
      if (!group.isActive) continue;
      if (group.maxSelect == 1) {
        final modId = _selectedRadioModifiers[group.id];
        if (modId != null) {
          final mod = group.modifiers.firstWhere((m) => m.id == modId);
          selected.add(mod);
        }
      } else {
        final modIds = _selectedMultiModifiers[group.id] ?? {};
        for (final modId in modIds) {
          final mod = group.modifiers.firstWhere((m) => m.id == modId);
          selected.add(mod);
        }
      }
    }
    return selected;
  }

  bool _isSelectionValid() {
    for (final group in widget.item.modifierGroups) {
      if (!group.isActive) continue;
      int selectedCount = 0;
      if (group.maxSelect == 1) {
        selectedCount = _selectedRadioModifiers.containsKey(group.id) ? 1 : 0;
      } else {
        selectedCount = _selectedMultiModifiers[group.id]?.length ?? 0;
      }

      if (selectedCount < group.minSelect) {
        return false;
      }
      if (group.maxSelect > 0 && selectedCount > group.maxSelect) {
        return false;
      }
    }
    return true;
  }

  double _calculateSingleItemPrice() {
    double price = widget.item.price;
    final selected = _getSelectedModifiers();
    for (final m in selected) {
      price += m.price;
    }
    return price;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double singlePrice = _calculateSingleItemPrice();
    final double totalPrice = singlePrice * _quantity;
    final bool isValid = _isSelectionValid();

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemCover(),
                  _buildItemDetails(),
                  _buildDivider(),
                  for (final group in widget.item.modifierGroups) ...[
                    if (group.isActive) ...[
                      _buildModifierGroupSection(group),
                      _buildDivider(),
                    ],
                  ],
                  _buildSpecialInstructions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomAction(totalPrice, isValid),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.item.nameTh,
              style: AppTypography.heading4,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48), // Balancing empty space
        ],
      ),
    );
  }

  Widget _buildItemCover() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            widget.item.imageUrl ??
                'https://plus.unsplash.com/premium_photo-1694141253763-209b4c8f8ace?w=600',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildItemDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.nameTh, style: AppTypography.heading3),
          if (widget.item.name != widget.item.nameTh) ...[
            const SizedBox(height: 4),
            Text(
              widget.item.name,
              style: AppTypography.caption4.copyWith(color: Colors.grey),
            ),
          ],
          if (widget.item.description != null &&
              widget.item.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.item.description!,
              style: AppTypography.caption4.copyWith(color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'ราคาเริ่มต้น ฿${widget.item.price.toStringAsFixed(0)}',
            style: AppTypography.heading4.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[200]);
  }

  Widget _buildModifierGroupSection(ModifierGroupModel group) {
    final isRadio = group.maxSelect == 1;

    String hintText = '';
    if (group.minSelect > 0) {
      hintText = 'จำเป็นต้องเลือกอย่างน้อย ${group.minSelect} รายการ';
    } else {
      hintText = 'เลือกซื้อเพิ่มได้';
    }
    if (group.maxSelect > 0 && group.maxSelect != 1) {
      hintText += ' (สูงสุด ${group.maxSelect} รายการ)';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group.name, style: AppTypography.label1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      group.minSelect > 0 ? Colors.red[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  hintText,
                  style: AppTypography.caption5.copyWith(
                    color: group.minSelect > 0 ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final mod in group.modifiers) ...[
            if (mod.isAvailable)
              isRadio
                  ? _buildRadioTile(group.id, mod)
                  : _buildCheckboxTile(group.id, mod, group.maxSelect),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioTile(String groupId, ModifierModel mod) {
    final isSelected = _selectedRadioModifiers[groupId] == mod.id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRadioModifiers[groupId] = mod.id;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(mod.name, style: AppTypography.caption3)),
            if (mod.price > 0)
              Text(
                '+ ฿${mod.price.toStringAsFixed(0)}',
                style: AppTypography.caption3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(String groupId, ModifierModel mod, int maxSelect) {
    final selectedSet = _selectedMultiModifiers[groupId] ?? {};
    final isSelected = selectedSet.contains(mod.id);

    return InkWell(
      onTap: () {
        setState(() {
          final newSet = Set<String>.from(selectedSet);
          if (isSelected) {
            newSet.remove(mod.id);
          } else {
            if (maxSelect == 0 || newSet.length < maxSelect) {
              newSet.add(mod.id);
            }
          }
          _selectedMultiModifiers[groupId] = newSet;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppColors.primary : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(mod.name, style: AppTypography.caption3)),
            if (mod.price > 0)
              Text(
                '+ ฿${mod.price.toStringAsFixed(0)}',
                style: AppTypography.caption3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รายละเอียดเพิ่มเติม', style: AppTypography.label1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'ไม่จำเป็นต้องระบุ',
                  style: AppTypography.caption5.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200, // SCRUM-44: items[].notes ≤ 200 chars
            decoration: InputDecoration(
              hintText: 'เช่น เผ็ดน้อย, ไม่ใส่กระเทียมเจียว',
              hintStyle: AppTypography.caption3.copyWith(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(double totalPrice, bool isValid) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: _decrement,
              ),
              const SizedBox(width: 24),
              Text('$_quantity', style: AppTypography.heading2),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: _increment,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isValid
                  ? () {
                      Navigator.of(context).pop();
                      if (widget.onAddToCart != null) {
                        widget.onAddToCart!(
                          _quantity,
                          totalPrice,
                          _getSelectedModifiers(),
                          _commentController.text.trim(),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isValid ? AppColors.foundationGreen500 : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'เพิ่มไปยังตะกร้า - ฿${totalPrice.toStringAsFixed(0)}',
                style: AppTypography.heading5.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
