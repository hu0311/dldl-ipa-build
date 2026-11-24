import UIKit
import WebKit

/// H5 游戏壳：全屏 WKWebView，跟随网页方向，失败可重试
final class WebViewController: UIViewController {

    // ======== 只改这里 ========
    private let startURLString = "https://www.youyougu.cn/?ct=h5login&gid=225"
    // =========================

    private var webView: WKWebView!
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let errorBox = UIView()
    private let errorLabel = UILabel()
    private var progressObs: NSKeyValueObservation?

    private var startURL: URL? { URL(string: startURLString) }

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupWebView()
        setupProgress()
        setupErrorBox()
        // 玩游戏时不自动锁屏
        UIApplication.shared.isIdleTimerDisabled = true
        load()
    }

    deinit {
        progressObs?.invalidate()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

    // MARK: - UI

    private func setupWebView() {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.javaScriptCanOpenWindowsAutomatically = true
        cfg.websiteDataStore = WKWebsiteDataStore.default()

        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        progressObs = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            guard let self = self else { return }
            let p = Float(wv.estimatedProgress)
            self.progressBar.setProgress(p, animated: true)
            self.progressBar.isHidden = p >= 0.99
        }
    }

    private func setupProgress() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = UIColor(red: 0.13, green: 0.78, blue: 0.55, alpha: 1)
        progressBar.trackTintColor = .clear
        progressBar.setProgress(0, animated: false)
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.topAnchor.constraint(equalTo: view.topAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func setupErrorBox() {
        errorBox.translatesAutoresizingMaskIntoConstraints = false
        errorBox.backgroundColor = .black
        errorBox.isHidden = true

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.textColor = UIColor(white: 0.85, alpha: 1)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.text = "加载失败，请检查网络后重试"

        let retry = UIButton(type: .system)
        retry.translatesAutoresizingMaskIntoConstraints = false
        retry.setTitle("重新加载", for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        retry.addTarget(self, action: #selector(onRetry), for: .touchUpInside)

        errorBox.addSubview(errorLabel)
        errorBox.addSubview(retry)
        view.addSubview(errorBox)

        NSLayoutConstraint.activate([
            errorBox.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorBox.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorBox.topAnchor.constraint(equalTo: view.topAnchor),
            errorBox.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: errorBox.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorBox.centerYAnchor, constant: -20),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: errorBox.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: errorBox.trailingAnchor, constant: -32),

            retry.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            retry.centerXAnchor.constraint(equalTo: errorBox.centerXAnchor)
        ])
    }

    // MARK: - 加载

    private func load() {
        guard let url = startURL else {
            showError("起始地址不合法")
            return
        }
        errorBox.isHidden = true
        webView.load(URLRequest(url: url))
    }

    @objc private func onRetry() {
        if webView.url == nil {
            load()
        } else {
            errorBox.isHidden = true
            webView.reload()
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorBox.isHidden = false
        progressBar.isHidden = true
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = (url.scheme ?? "").lowercased()
        // 微信/支付宝/客服等外部 scheme 交给系统
        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "file" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        errorBox.isHidden = true
        progressBar.isHidden = true
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        let code = (error as NSError).code
        // -999 是用户主动取消/跳转，不算失败
        if code == -999 { return }
        showError("加载失败（\(code)）\n请检查网络后重试")
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}
