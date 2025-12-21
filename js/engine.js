
// Engine Jophiel - Core Logic

const codeInput = document.getElementById('code-input');
const previewFrame = document.getElementById('preview-frame');
const runBtn = document.getElementById('run-btn');
const feedbackDiv = document.getElementById('feedback');

// Función para actualizar el preview
function updatePreview() {
    const code = codeInput.value;
    const previewDocument = previewFrame.contentDocument || previewFrame.contentWindow.document;

    previewDocument.open();
    previewDocument.write(code);
    previewDocument.close();
}

// Función para mostrar feedback
function showFeedback(message, type) {
    feedbackDiv.style.display = 'block';
    feedbackDiv.className = type; // 'success' o 'error'
    feedbackDiv.innerText = message;
}

// Event Listeners
if (runBtn) {
    runBtn.addEventListener('click', () => {
        updatePreview();
        if (typeof validateLesson === 'function') {
            validateLesson(codeInput.value);
        }
    });
}

// Inicializar preview vacío
if (previewFrame) {
    // Inject basic styles into iframe
    const previewDocument = previewFrame.contentDocument || previewFrame.contentWindow.document;
    previewDocument.open();
    previewDocument.write(''); // Empieza limpio
    previewDocument.close();
}
