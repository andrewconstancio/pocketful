import SwiftUI

struct HomeView: View {
    
    @State private var homeViewModel: HomeViewModel
    
    init(dependencies: AppDependencies) {
        _homeViewModel = State(initialValue: dependencies.makeHomeViewModel())
    }
    
    var body: some View {
        Button {
            homeViewModel.signOut()
        } label: {
            Text("Sign out")
        }
    }
}

//#Preview {
//    HomeView()
//}
