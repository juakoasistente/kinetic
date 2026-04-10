import SwiftUI
import MapKit

struct RouteSetupView: View {
    @Binding var path: [RecordRoute]
    @Environment(\.dismiss) private var dismiss

    @State private var startPin: CLLocationCoordinate2D?
    @State private var endPin: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var mapRegion: MKCoordinateRegion?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearch = false
    @State private var placingPin: PinType = .start

    enum PinType {
        case start, end
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image("back")
                        .renderingMode(.template)
                        .foregroundStyle(.gravel)
                }

                Spacer()

                Text(localized: "tracking.routeSetup.title")
                    .font(.inter(14, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white)

                Spacer()

                Image("back")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gravel)
                TextField("", text: $searchText, prompt: Text(LanguageManager.shared.localizedString("tracking.routeSetup.searchPlaceholder")).foregroundStyle(.gravel))
                    .font(.inter(14, weight: .regular))
                    .foregroundStyle(.white)
                    .onSubmit {
                        searchAddress()
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gravel)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Pin selector
            HStack(spacing: 12) {
                pinButton(type: .start, label: LanguageManager.shared.localizedString("tracking.routeSetup.startLabel"), isSet: startPin != nil)
                pinButton(type: .end, label: LanguageManager.shared.localizedString("tracking.routeSetup.endLabel"), isSet: endPin != nil)

                if startPin != nil || endPin != nil {
                    Button {
                        startPin = nil
                        endPin = nil
                        placingPin = .start
                        HapticManager.impact(.light)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.gravel)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ZStack {
                // Map
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        UserAnnotation()

                        if let start = startPin {
                            Annotation("A", coordinate: start) {
                                ZStack {
                                    Circle()
                                        .fill(.stravaOrange)
                                        .frame(width: 32, height: 32)
                                    Text("A")
                                        .font(.inter(14, weight: .black))
                                        .foregroundStyle(.white)
                                }
                            }
                        }

                        if let end = endPin {
                            Annotation("B", coordinate: end) {
                                ZStack {
                                    Circle()
                                        .fill(.danger)
                                        .frame(width: 32, height: 32)
                                    Text("B")
                                        .font(.inter(14, weight: .black))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .mapStyle(KineticMapStyle.route)
                    .mapControls {
                        MapUserLocationButton()
                    }
                    .onMapCameraChange { context in
                        mapRegion = context.region
                    }
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                                HapticManager.impact(.light)
                                placePin(at: coordinate)
                            }
                    )
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: SpatialTapGesture())
                            .onEnded { value in
                                if case .second(true, let tap) = value, let tap {
                                    guard let coordinate = proxy.convert(tap.location, from: .local) else { return }
                                    HapticManager.impact(.medium)
                                    placePin(at: coordinate)
                                }
                            }
                    )
                }

                // Search results overlay
                if !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        selectSearchResult(item)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name ?? "Unknown")
                                                .font(.inter(14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            if let address = item.placemark.title {
                                                Text(address)
                                                    .font(.inter(12, weight: .regular))
                                                    .foregroundStyle(.gravel)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .background(.coal.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()
                }
            }

            // Distance info
            VStack(spacing: 8) {
                if let start = startPin, let end = endPin {
                    let distance = CLLocation(latitude: start.latitude, longitude: start.longitude)
                        .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
                    HStack(spacing: 6) {
                        Text(LanguageManager.shared.localizedString("tracking.routeSetup.distance"))
                            .font(.inter(12, weight: .medium))
                            .foregroundStyle(.gravel)
                        Text(String(format: "%.1f km", distance / 1000.0))
                            .font(.inter(16, weight: .black))
                            .foregroundStyle(.stravaOrange)
                    }
                } else {
                    Text(startPin == nil
                         ? LanguageManager.shared.localizedString("tracking.routeSetup.tapStart")
                         : LanguageManager.shared.localizedString("tracking.routeSetup.tapEnd"))
                        .font(.inter(13, weight: .medium))
                        .foregroundStyle(.gravel)
                }
            }
            .padding(.vertical, 12)

            // Confirm button
            Button {
                guard let start = startPin, let end = endPin else { return }
                HapticManager.impact(.medium)
                path.append(.waitingForStart(startCoordinate: start, endCoordinate: end))
            } label: {
                Text(localized: "tracking.routeSetup.confirm")
                    .font(.inter(15, weight: .black))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.stravaOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .opacity(startPin != nil && endPin != nil ? 1.0 : 0.4)
            .disabled(startPin == nil || endPin == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(.black)
        .navigationBarHidden(true)
        .swipeBack { dismiss() }
    }

    // MARK: - Helpers

    private func pinButton(type: PinType, label: String, isSet: Bool) -> some View {
        Button {
            placingPin = type
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(type == .start ? .stravaOrange : .danger)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.inter(12, weight: .bold))
                    .foregroundStyle(placingPin == type ? .white : .gravel)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(placingPin == type ? Color.white.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSet ? (type == .start ? Color.stravaOrange : .danger) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func placePin(at coordinate: CLLocationCoordinate2D) {
        switch placingPin {
        case .start:
            startPin = coordinate
            if endPin == nil { placingPin = .end }
        case .end:
            endPin = coordinate
        }
    }

    private func searchAddress() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        if let region = mapRegion {
            request.region = region
        }

        Task {
            let search = MKLocalSearch(request: request)
            if let response = try? await search.start() {
                searchResults = response.mapItems
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        placePin(at: coordinate)
        HapticManager.impact(.light)
        searchResults = []
        searchText = ""

        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                RouteSetupView(path: .constant([]))
            }
    }
}
