import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ibge_locations.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.onChanged,
    this.initialState,
    this.initialCity,
  });

  final String? initialState;
  final String? initialCity;
  final void Function(String state, String city, int municipalityId)? onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final http.Client client = http.Client();
  late final IbgeLocations locations = IbgeLocations(client);
  late Future<List<IbgeLocation>> states = locations.states;
  Future<List<IbgeLocation>>? cities;
  String? state;
  int? municipalityId;

  @override
  void initState() {
    super.initState();
    state = widget.initialState?.toUpperCase();
    if (state != null && state!.isNotEmpty) cities = locations.cities(state!);
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final width = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: FutureBuilder<List<IbgeLocation>>(
                  future: states,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return OutlinedButton(
                        onPressed: () => setState(() => states = locations.states),
                        child: const Text('Estados indisponíveis. Tentar novamente'),
                      );
                    }
                    final items = snapshot.data ?? const <IbgeLocation>[];
                    return DropdownButtonFormField<String>(
                      key: ValueKey('state-$state'),
                      initialValue: items.any((e) => e.code == state) ? state : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: snapshot.hasData ? 'Estado' : 'Carregando estados',
                      ),
                      items: [
                        for (final item in items)
                          DropdownMenuItem(value: item.code, child: Text(item.name)),
                      ],
                      onChanged: snapshot.hasData
                          ? (value) => setState(() {
                                state = value;
                                municipalityId = null;
                                cities = value == null ? null : locations.cities(value);
                              })
                          : null,
                    );
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: FutureBuilder<List<IbgeLocation>>(
                  future: cities,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return OutlinedButton(
                        onPressed: () => setState(() {
                          if (state != null) cities = locations.cities(state!);
                        }),
                        child: const Text('Cidades indisponíveis. Tentar novamente'),
                      );
                    }
                    final items = snapshot.data ?? const <IbgeLocation>[];
                    final selected = items.where((e) =>
                        e.id == municipalityId ||
                        (municipalityId == null && e.name == widget.initialCity &&
                            state == widget.initialState?.toUpperCase())).firstOrNull;
                    return DropdownButtonFormField<int>(
                      key: ValueKey('city-$state-$municipalityId'),
                      initialValue: selected?.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: snapshot.hasData ? 'Cidade' : 'Escolha o estado',
                      ),
                      items: [
                        for (final item in items)
                          DropdownMenuItem(value: item.id, child: Text(
                            item.name, overflow: TextOverflow.ellipsis,
                          )),
                      ],
                      onChanged: snapshot.hasData ? (value) {
                        final choice = items.where((e) => e.id == value).firstOrNull;
                        if (choice == null || state == null) return;
                        setState(() => municipalityId = choice.id);
                        widget.onChanged?.call(state!, choice.name, choice.id);
                      } : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}
