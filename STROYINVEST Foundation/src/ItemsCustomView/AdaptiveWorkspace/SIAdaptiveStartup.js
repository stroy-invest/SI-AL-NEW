// The layout must exist before AL sends RenderTree / RenderProducts.
(function () {
    let started = false;
    function start() {
        if (started) return;
        const host = document.getElementById('controlAddIn');
        if (!host) {
            console.error('SI Adaptive Hierarchy: controlAddIn host is not available');
            return;
        }
        try {
            siAdaptiveInitializeLayout();
            started = true;
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
        } catch (error) {
            console.error('SI Adaptive Hierarchy initialization failed:', error);
            host.textContent = 'Помилка ініціалізації дерева товарів. Перевірте консоль браузера (F12).';
        }
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start, { once: true });
    } else {
        start();
    }
})();
