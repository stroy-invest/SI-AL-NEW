// Initialize only after Business Central has created the controlAddIn host.
(function () {
    let started = false;
    let attempts = 0;
    function start() {
        if (started) return;
        const host = document.getElementById('controlAddIn');
        if (!host) {
            if (++attempts < 120) { window.requestAnimationFrame(start); return; }
            console.error('SI Hierarchy V3: controlAddIn host not found after waiting');
            return;
        }
        try {
            if (typeof siV3InitializeLayout !== 'function')
                throw new Error('SI Hierarchy V3 layout script is not loaded');
            siV3InitializeLayout();
            started = true;
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
        } catch (error) {
            console.error('SI Hierarchy V3 initialization failed:', error);
            host.textContent = 'Помилка ініціалізації дерева товарів. Перевірте Console (F12).';
        }
    }
    if (document.readyState === 'loading')
        document.addEventListener('DOMContentLoaded', start, { once: true });
    else start();
})();
