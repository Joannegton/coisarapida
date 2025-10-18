const API_URL = 'http://localhost:3000/seguranca';
// Estado da página de detalhes
let currentVerification = null;
let imageZoom = 1;
let imageRotation = 0;

// Inicialização
document.addEventListener('DOMContentLoaded', () => {
    console.log('Página de detalhes carregada');
    initializePage();
});

// Inicializar página
function initializePage() {
    // Verificar se há dados da verificação na URL
    const urlParams = new URLSearchParams(window.location.search);
    const verificationData = urlParams.get('data');

    if (!verificationData) {
        showToast('Dados da verificação não encontrados', 'error');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 2000);
        return;
    }

    try {
        currentVerification = JSON.parse(decodeURIComponent(verificationData));
        loadVerificationDetails();
    } catch (error) {
        console.error('Erro ao parsear dados da verificação:', error);
        showToast('Erro ao carregar dados da verificação', 'error');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 2000);
        return;
    }

    // Configurar event listeners
    setupEventListeners();
}

// Configurar event listeners
function setupEventListeners() {
    // Botão voltar
    document.getElementById('backBtn').addEventListener('click', () => {
        window.location.href = 'index.html';
    });

    // Botão logout
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);

    // Controles de imagem
    document.getElementById('zoomIn').addEventListener('click', () => {
        imageZoom += 0.2;
        updateImageTransform();
    });

    document.getElementById('zoomOut').addEventListener('click', () => {
        imageZoom = Math.max(0.5, imageZoom - 0.2);
        updateImageTransform();
    });

    document.getElementById('rotateBtn').addEventListener('click', () => {
        imageRotation += 90;
        updateImageTransform();
    });

    // Ações
    document.getElementById('aprovarBtn').addEventListener('click', () => {
        if (currentVerification) {
            aprovarVerificacao(currentVerification);
        }
    });

    document.getElementById('rejeitarBtn').addEventListener('click', () => {
        document.getElementById('rejeicaoForm').style.display = 'block';
    });

    document.getElementById('cancelarRejeicao').addEventListener('click', () => {
        document.getElementById('rejeicaoForm').style.display = 'none';
        document.getElementById('motivoRejeicao').value = '';
    });

    document.getElementById('confirmarRejeicao').addEventListener('click', () => {
        const motivo = document.getElementById('motivoRejeicao').value.trim();
        if (!motivo) {
            showToast('Digite um motivo para a rejeição', 'error');
            return;
        }
        if (currentVerification) {
            rejeitarVerificacao(currentVerification, motivo);
        }
    });
}

// Carregar detalhes da verificação
function loadVerificationDetails() {
    if (!currentVerification) return;

    // Preencher dados do usuário
    document.getElementById('detailNome').textContent = currentVerification.usuario?.nome || '-';
    document.getElementById('detailCPF').textContent = currentVerification.usuario?.cpf || '-';
    document.getElementById('detailEmail').textContent = currentVerification.usuario?.email || '-';
    document.getElementById('detailTelefone').textContent = currentVerification.usuario?.telefone || '-';
    // Formatar endereço se for um objeto
    let enderecoFormatado = '-';
    if (currentVerification.usuario?.endereco) {
        const endereco = currentVerification.usuario.endereco;
        if (typeof endereco === 'string') {
            enderecoFormatado = endereco;
        } else if (typeof endereco === 'object') {
            // Formatar endereço do objeto
            enderecoFormatado = `${endereco.rua || ''}, ${endereco.numero || ''}`;
            if (endereco.complemento) {
                enderecoFormatado += `, ${endereco.complemento}`;
            }
            enderecoFormatado += ` - ${endereco.bairro || ''}, ${endereco.cidade || ''} - ${endereco.estado || ''}, ${endereco.cep || ''}`;
            if (endereco.pais && endereco.pais !== 'Brasil') {
                enderecoFormatado += `, ${endereco.pais}`;
            }
        }
    }
    document.getElementById('detailEndereco').textContent = enderecoFormatado;

    // Preencher dados da verificação
    if (currentVerification.dataSolicitacao) {
        const dataSolicitacao = new Date(currentVerification.dataSolicitacao);
        document.getElementById('detailDataSolicitacao').textContent = dataSolicitacao.toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    } else {
        document.getElementById('detailDataSolicitacao').textContent = '-';
    }

    document.getElementById('detailTipoDocumento').textContent = currentVerification.tipoDocumento || '-';
    document.getElementById('detailObservacoes').textContent = currentVerification.observacoesUsuario || '-';

    // Carregar imagem
    if (currentVerification.comprovanteUrl) {
        try {
            document.getElementById('detailImagem').src = currentVerification.comprovanteUrl;
            document.getElementById('modalImage').src = currentVerification.comprovanteUrl;
            document.getElementById('downloadBtn').href = currentVerification.comprovanteUrl;
        } catch (error) {
            console.error('Erro ao carregar imagem:', error);
            showToast('Erro ao carregar imagem do comprovante', 'error');
        }
    }
}

// Atualizar transformação da imagem
function updateImageTransform() {
    const img = document.getElementById('detailImagem');
    img.style.transform = `scale(${imageZoom}) rotate(${imageRotation}deg)`;
}

// Aprovar verificação
async function aprovarVerificacao(verificacao) {
    try {
        const currentUser = firebase.auth().currentUser;
        if (!currentUser) {
            showToast('Usuário não autenticado. Faça login novamente.', 'error');
            setTimeout(() => {
                window.location.href = 'index.html';
            }, 2000);
            return;
        }

        const token = await currentUser.getIdToken();

        const response = await fetch(`${API_URL}/verificacao-residencia/${verificacao.id}/processar`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                idComprovanteResidencia: verificacao.id,
                status: 'aprovado',
                motivoRejeicao: '',
                observacoes: ''
            })
        });

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || 'Erro ao aprovar verificação');
        }

        showToast('Verificação aprovada com sucesso!', 'success');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 2000);

    } catch (error) {
        console.error('Erro ao aprovar:', error);
        showToast('Erro ao aprovar verificação: ' + error.message, 'error');
    }
}

// Rejeitar verificação
async function rejeitarVerificacao(verificacao, motivo) {
    try {
        const currentUser = firebase.auth().currentUser;
        if (!currentUser) {
            showToast('Usuário não autenticado. Faça login novamente.', 'error');
            setTimeout(() => {
                window.location.href = 'index.html';
            }, 2000);
            return;
        }

        const token = await currentUser.getIdToken();

        const response = await fetch(`${API_URL}/verificacao-residencia/${verificacao.id}/processar`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                idComprovanteResidencia: verificacao.id,
                status: 'REJEITADO',
                motivoRejeicao: motivo,
                observacoes: ''
            })
        });

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || 'Erro ao rejeitar verificação');
        }

        showToast('Verificação rejeitada', 'info');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 2000);

    } catch (error) {
        console.error('Erro ao rejeitar:', error);
        showToast('Erro ao rejeitar verificação: ' + error.message, 'error');
    }
}

// Handle logout
async function handleLogout() {
    try {
        await firebase.auth().signOut();
        window.location.href = 'index.html';
    } catch (error) {
        showToast('Erro ao fazer logout.', 'error');
    }
}

// Mostrar toast
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    const iconMap = {
        success: 'fa-check-circle',
        error: 'fa-exclamation-circle',
        info: 'fa-info-circle'
    };

    toast.innerHTML = `
        <i class="fas ${iconMap[type]}"></i>
        <span>${message}</span>
    `;

    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Abrir modal da imagem em tela cheia
function openImageModal() {
    document.getElementById('imageModal').style.display = 'flex';
    document.body.style.overflow = 'hidden'; // Previne scroll da página
}

// Fechar modal da imagem
function closeImageModal() {
    document.getElementById('imageModal').style.display = 'none';
    document.body.style.overflow = 'auto'; // Restaura scroll da página
}