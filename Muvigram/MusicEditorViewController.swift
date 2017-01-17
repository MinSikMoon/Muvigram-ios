//
//  MusicEditorViewController.swift
//  Muvigram
//
//  Created by 박정이 on 2017. 1. 10..
//  Copyright © 2017년 com.estsoft. All rights reserved.
//

import UIKit
import PopupDialog
import SCWaveformView

class MusicEditorViewController: UITableViewController {

    var videosInfo = VideosInfo()
    
    fileprivate var resultSerchController = UISearchController()
    fileprivate var searchActive: Bool = false
    fileprivate var isScwaveScroll : Bool = false
    
    @IBOutlet var searchViewContrainr: UIView!
    
    fileprivate var scwaveScrollView: SCScrollableWaveformView!
    
    // @inject
    public var presenter: MusicPresenter<MusicEditorViewController>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load music item list
        presenter.loadMusics()
        // Search bar settings
        viewInitialization()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.getMusicCountWithShouldshow(resultSerchActive: resultSerchController.isActive)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return presenter.bindMusicItemCellWithShouldshow(resultSerchActive: resultSerchController.isActive,
                                                         cellForRowAt: indexPath,
                                                         dequeueReusableCellFunction: tableView.dequeueReusableCell)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = (tableView.cellForRow(at: indexPath) as! MusicTableViewCell).mpMediaItem?.assetURL! {
            scwaveScrollView.delegate = self
            scwaveScrollView.cmDelegate = self
            presenter.selectMusic(musicUrl: url)
        }
    }
    
    // Item height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func closeSearchBarWindow() {
        self.resultSerchController.isActive = false
    }
    
    @IBAction func clickBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil);
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editorSegue"){
            let vc = segue.destination as! EditorViewController
            vc.videosInfo = videosInfo
        }
    }
}

// Return results based on search in table view
extension MusicEditorViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        presenter.updateSearchResults(for: searchController)
    }
}

// MARK - Initial view settings
extension MusicEditorViewController: CmTimeDelegate {
    // Set SearchBar
    func viewInitialization() {
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: self.view.bounds.size.width - margin * 4.0, height: 120)
        
        scwaveScrollView = SCScrollableWaveformView(frame: rect)
        scwaveScrollView.showsVerticalScrollIndicator = false
        scwaveScrollView.showsHorizontalScrollIndicator = false
        scwaveScrollView.bounces = false
        
        self.resultSerchController = UISearchController(searchResultsController: nil)
        self.resultSerchController.searchResultsUpdater = self
        
        let searchBar = self.resultSerchController.searchBar
        
        (searchBar.value(forKey: "searchField") as! UITextField).backgroundColor = UIColor(red: CGFloat(0.867), green: CGFloat(0.875), blue: CGFloat(0.878), alpha: CGFloat(1.00))
        searchBar.barTintColor = UIColor(red: CGFloat(0.984), green: CGFloat(0.984), blue: CGFloat(0.984), alpha: CGFloat(1.00))
        
        searchViewContrainr.addSubview(searchBar)
        searchBar.sizeToFit()
    }
    
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if isScwaveScroll {
            scrollView.setContentOffset(scrollView.contentOffset, animated: true)
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { //OK
        if isScwaveScroll {
            self.presenter.modifyPlayerPause()
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { //OK
        if isScwaveScroll {
            self.presenter.modifyPlayerPlay()
        }
    }
    
    public func currentlySelectedPlaybackRange(_ startRange: CMTimeRange, end endTime: CMTime) {
        self.presenter.setModifyPlayerRange(startRange, end: endTime)
    }
}

extension MusicEditorViewController: MusicMvpView {
    // Updates the music item to the table.
    func updateMusicWithTable() {
        tableView.reloadData()
    }
    
    func setWaveformViewAsset(asset: AVAsset) {
        scwaveScrollView.waveformView.asset = asset
    }
    
    func setWaveformViewPrecision() {
        scwaveScrollView.waveformView.precision = 1
    }
    
    func setWaveformViewTimeRange(range: CMTimeRange) {
        scwaveScrollView.waveformView.timeRange = range
    }
    
    func setWaveformViewProgress(time: CMTime) {
        scwaveScrollView.waveformView.progressTime = time
    }
    
    func getWaveformViewTimeRangeStart() -> CMTime {
        return scwaveScrollView.waveformView.timeRange.start
    }
    
    func getWaveformViewAssetDuration() -> CMTime {
        return scwaveScrollView.waveformView.asset.duration
    }
    
    func showMusicRangeAlert() {
        isScwaveScroll = true
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alertController.view.addSubview(scwaveScrollView)
        let somethingAction = UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
            self.presenter.modifyPlayerRemoveTimeObserver()
            self.presenter.modifyPlayerPause();
            self.isScwaveScroll = false
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            self.presenter.modifyPlayerRemoveTimeObserver()
            self.presenter.modifyPlayerPause();
            self.isScwaveScroll = false
        })
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion:{})
        }
        self.presenter.musicSectionSelectionPlayback()
    }
}