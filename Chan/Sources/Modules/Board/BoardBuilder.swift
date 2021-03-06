//
//  BoardBuilder.swift
//  Chan
//
//  Created by Mikhail Malyshev on 09.09.2018.
//  Copyright © 2018 Mikhail Malyshev. All rights reserved.
//

import RIBs

protocol BoardDependency: Dependency {
}

final class BoardComponent: Component<BoardDependency>, ThreadDependency, BoardsListDependency, WebAcceptDependency, WriteDependency {
    var writeModuleState: WriteModuleState { return .create }

}

// MARK: - Builder

protocol BoardBuildable: Buildable {
    func build(withListener listener: BoardListener) -> BoardRouting
}

final class BoardBuilder: Builder<BoardDependency>, BoardBuildable {

    
    private let interactor: BoardInteractor
    private let vc: BoardViewControllable
    
    override init(dependency: BoardDependency) {
        
        let service = BoardService()
        let imageboardService = ImageboardService.instance()
        let viewController = UIStoryboard(name: "BoardViewController", bundle: nil).instantiateViewController(withIdentifier: "BoardViewController") as! BoardViewController
        
        self.vc = viewController
        self.interactor = BoardInteractor(presenter: viewController, imageboardService: imageboardService, service: service, favoriteService: FavoriteService())

        
        super.init(dependency: dependency)
    }
    
    var boardInput: BoardInputProtocol {
        return self.interactor
    }

    func build(withListener listener: BoardListener) -> BoardRouting {
        let component = BoardComponent(dependency: dependency)
        
        self.interactor.listener = listener
        
        let threadBuilder = ThreadBuilder(dependency: component)
        let agreement = WebAcceptBuilder(dependency: component)
        let createThread = WriteBuilder(dependency: component)
        
        return BoardRouter(interactor: self.interactor, viewController: self.vc, thread: threadBuilder, agreement: agreement, createThread: createThread)
    }
}
