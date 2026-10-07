(function () {
    var host = document.getElementById('controlAddIn');
    if (!host) return;

    host.innerHTML = '';

    var button = document.createElement('button');
    button.type = 'button';
    button.textContent = 'Додати категорію';
    button.title = 'Додати категорію товарів';
    button.style.height = '32px';
    button.style.minWidth = '160px';
    button.style.padding = '0 16px';
    button.style.border = '1px solid #8a8886';
    button.style.borderRadius = '2px';
    button.style.background = '#ffffff';
    button.style.color = '#323130';
    button.style.fontFamily = 'Segoe UI, sans-serif';
    button.style.fontSize = '14px';
    button.style.fontWeight = '600';
    button.style.cursor = 'pointer';
    button.onclick = SIAddVscCategory;

    host.appendChild(button);
})();
