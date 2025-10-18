// Estado da aplicação
let currentFilter = 'todas';
let currentView = 'verificacoes';
let currentVerification = null;
let imageZoom = 1;
let imageRotation = 0;
let currentUser = null;

// Inicialização
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM carregado, inicializando app admin...');
    initializeAuth();
    initializeEventListeners();
});

// ===== AUTENTICAÇÃO E CONTROLE DE ACESSO =====

// Inicializar autenticação
function initializeAuth() {
    console.log('initializeAuth chamado');
    firebase.auth().onAuthStateChanged(async (user) => {
        console.log('onAuthStateChanged chamado, user:', user ? user.uid : 'null');
        if (user) {
            console.log('Usuário logado, verificando se é admin...');
            // Verificar se é admin
            try {
                const userDoc = await db.collection('usuarios').doc(user.uid).get();
                const userData = userDoc.data();
                console.log('Dados do usuário:', userData);

                if (userData && userData.isAdmin) {
                    console.log('Usuário é admin, mostrando painel');
                    currentUser = user;
                    showAdminPanel(userData);
                } else {
                    console.log('Usuário não é admin, mostrando login');
                    showLoginPage();
                    showToast('Acesso negado. Você não tem permissões de administrador.', 'error');
                    await firebase.auth().signOut();
                }
            } catch (error) {
                console.error('Erro ao verificar permissões:', error);
                showLoginPage();
                showToast('Erro ao verificar permissões.', 'error');
                // Removido signOut para evitar loop
                // await firebase.auth().signOut();
            }
        } else {
            console.log('Nenhum usuário logado, mostrando login');
            currentUser = null;
            showLoginPage();
        }
    });
}

// Mostrar página de login
function showLoginPage() {
    document.getElementById('loginPage').style.display = 'flex';
    document.getElementById('adminPanel').style.display = 'none';
}

// Mostrar painel admin
function showAdminPanel(userData) {
    document.getElementById('loginPage').style.display = 'none';
    document.getElementById('adminPanel').style.display = 'block';

    // Atualizar nome do admin
    document.getElementById('adminName').textContent = userData.nome || userData.email;

    // Carregar dados
    loadVerificacoes();
    loadEstatisticas();
}

// Handle login form submission
async function handleLogin(e) {
    console.log('handleLogin chamado');
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    console.log('Tentando login com:', email);

    const loginBtn = e.target.querySelector('.btn-login');
    const messageDiv = document.getElementById('loginMessage');

    // Desabilitar botão
    loginBtn.disabled = true;
    loginBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Entrando...';

    try {
        await firebase.auth().signInWithEmailAndPassword(email, password);
        messageDiv.style.display = 'none';
    } catch (error) {
        messageDiv.textContent = getAuthErrorMessage(error.code);
        messageDiv.className = 'login-message error';
        messageDiv.style.display = 'block';

        // Reabilitar botão
        loginBtn.disabled = false;
        loginBtn.innerHTML = '<i class="fas fa-sign-in-alt"></i> Entrar';
    }
}

// Handle logout
async function handleLogout() {
    try {
        await firebase.auth().signOut();
        showToast('Logout realizado com sucesso!', 'success');
    } catch (error) {
        showToast('Erro ao fazer logout.', 'error');
    }
}

// Get authentication error messages
function getAuthErrorMessage(errorCode) {
    switch (errorCode) {
        case 'auth/user-not-found':
            return 'Usuário não encontrado.';
        case 'auth/wrong-password':
            return 'Senha incorreta.';
        case 'auth/invalid-email':
            return 'Email inválido.';
        case 'auth/user-disabled':
            return 'Conta desabilitada.';
        case 'auth/too-many-requests':
            return 'Muitas tentativas. Tente novamente mais tarde.';
        default:
            return 'Erro ao fazer login. Tente novamente.';
    }
}

// Event Listeners
function initializeEventListeners() {
    console.log('Inicializando event listeners...');

    // Login form
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        console.log('Login form encontrado, adicionando listener');
        loginForm.addEventListener('submit', handleLogin);
    } else {
        console.log('Login form NÃO encontrado');
    }

    // Logout
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        console.log('Logout button encontrado, adicionando listener');
        logoutBtn.addEventListener('click', handleLogout);
    } else {
        console.log('Logout button NÃO encontrado');
    }

    // Navegação
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const view = item.dataset.view;
            switchView(view);
        });
    });

    // Filtros
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            currentFilter = btn.dataset.filter;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            loadVerificacoes();
        });
    });

    // Refresh
    document.getElementById('refreshBtn').addEventListener('click', () => {
        loadVerificacoes();
        showToast('Verificações atualizadas', 'success');
    });

    // Logout
    document.getElementById('logoutBtn').addEventListener('click', () => {
        auth.signOut().then(() => {
            showToast('Logout realizado com sucesso', 'info');
        });
    });

    // Modal
    document.querySelector('.modal-close').addEventListener('click', closeModal);
    document.getElementById('modalDetalhes').addEventListener('click', (e) => {
        if (e.target.id === 'modalDetalhes') {
            closeModal();
        }
    });

    // Image controls
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

    // Ações do modal
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

    // Search
    document.getElementById('searchHistorico').addEventListener('input', (e) => {
        filterHistorico(e.target.value);
    });
}

// Trocar visualização
function switchView(view) {
    currentView = view;
    
    // Atualizar navegação
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.view === view) {
            item.classList.add('active');
        }
    });

    // Atualizar views
    document.querySelectorAll('.view').forEach(v => {
        v.classList.remove('active');
    });
    document.getElementById(`${view}View`).classList.add('active');

    // Carregar dados se necessário
    if (view === 'historico') {
        loadHistorico();
    }
}

// Carregar verificações pendentes
async function loadVerificacoes(limite) {
    const list = document.getElementById('verificacoesList');
    const loading = document.getElementById('loadingSpinner');
    const empty = document.getElementById('emptyState');
    
    loading.style.display = 'block';
    empty.style.display = 'none';
    
    // Limpar cards existentes
    list.querySelectorAll('.verificacao-card').forEach(card => card.remove());

    try {
        // Buscar verificações pendentes do Firestore
        const url = new URL('http://localhost:3000/seguranca/verificacao-residencia/pendentes');
        if (limite) {
            url.searchParams.append('limite', limite);
        }

        let response = await fetch(url.toString(), {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        const result = await response.json();
        console.log('Verificações pendentes carregadas:', result);
        
        loading.style.display = 'none';

        if (!result.success || !result.data || result.data.length === 0) {
            empty.style.display = 'block';
            updateBadges(0, 0, 0);
            return;
        }

        // Processar verificações
        const verificacoes = [];
        for (const item of result.data) {
            verificacoes.push({
                id: item.id,
                comprovanteUrl: item.comprovanteUrl,
                tipoDocumento: item.tipoComprovante,
                observacoesUsuario: item.observacoesUsuario,
                dataSolicitacao: new Date(item.dataSubmissao),
                usuarioId: item.usuario.id,
                usuario: item.usuario
            });
        }

        // Aplicar filtro
        const filteredVerificacoes = applyFilter(verificacoes);

        // Atualizar badges
        const residenciaCount = verificacoes.filter(v => v.tipoDocumento).length;
        const telefoneCount = 0; // SMS verificações não têm pendências manuais
        updateBadges(verificacoes.length, residenciaCount, telefoneCount);

        if (filteredVerificacoes.length === 0) {
            empty.style.display = 'block';
            return;
        }

        // Renderizar cards
        filteredVerificacoes.forEach(verificacao => {
            const card = createVerificacaoCard(verificacao);
            list.appendChild(card);
        });

    } catch (error) {
        console.error('Erro ao carregar verificações:', error);
        showToast('Erro ao carregar verificações', 'error');
        loading.style.display = 'none';
    }
}

// Aplicar filtro
function applyFilter(verificacoes) {
    if (currentFilter === 'todas') {
        return verificacoes;
    } else if (currentFilter === 'residencia') {
        return verificacoes.filter(v => v.tipoDocumento);
    } else if (currentFilter === 'telefone') {
        return verificacoes.filter(v => v.telefone);
    }
    return verificacoes;
}

// Criar card de verificação
function createVerificacaoCard(verificacao) {
    const card = document.createElement('div');
    card.className = 'verificacao-card';
    
    const tipo = verificacao.tipoDocumento ? 'residencia' : 'telefone';
    const icon = tipo === 'residencia' ? 'fa-home' : 'fa-phone';
    const tipoLabel = tipo === 'residencia' ? 'Residência' : 'Telefone';
    
    const dataSolicitacao = verificacao.dataSolicitacao;
    const dataFormatada = dataSolicitacao ? 
        new Intl.DateTimeFormat('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(dataSolicitacao) : 'Data não disponível';

    card.innerHTML = `
        <div class="verificacao-icon ${tipo}">
            <i class="fas ${icon}"></i>
        </div>
        <div class="verificacao-info">
            <h3>${verificacao.usuario?.nome || 'Usuário'}</h3>
            <div class="verificacao-meta">
                <span>
                    <i class="fas fa-tag"></i>
                    ${tipoLabel}
                </span>
                <span>
                    <i class="fas fa-envelope"></i>
                    ${verificacao.usuario?.email || 'Email não disponível'}
                </span>
                <span>
                    <i class="fas fa-clock"></i>
                    ${dataFormatada}
                </span>
            </div>
        </div>
        <div class="verificacao-actions">
            <button class="btn-icon btn-view" title="Ver detalhes">
                <i class="fas fa-eye"></i>
            </button>
        </div>
    `;

    card.querySelector('.btn-view').addEventListener('click', () => {
        openDetalhesPage(verificacao);
    });

    return card;
}

// Abrir modal com detalhes
async function openModal(verificacao) {
    currentVerification = verificacao;
    
    // Resetar zoom e rotação
    imageZoom = 1;
    imageRotation = 0;

    // Preencher dados do usuário
    document.getElementById('detailNome').textContent = verificacao.usuario?.nome || '-';
    document.getElementById('detailEmail').textContent = verificacao.usuario?.email || '-';
    document.getElementById('detailTelefone').textContent = verificacao.usuario?.telefone || '-';
    
    const dataCadastro = verificacao.usuario?.dataCriacao?.toDate();
    document.getElementById('detailDataCadastro').textContent = dataCadastro ?
        new Intl.DateTimeFormat('pt-BR').format(dataCadastro) : '-';

    // Preencher dados da verificação
    const tipo = verificacao.tipoDocumento ? 'Verificação de Residência' : 'Verificação de Telefone';
    document.getElementById('detailTipo').textContent = tipo;
    
    const dataSolicitacao = verificacao.dataSolicitacao;
    document.getElementById('detailDataSolicitacao').textContent = dataSolicitacao ?
        new Intl.DateTimeFormat('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(dataSolicitacao) : '-';
    
    document.getElementById('detailTipoDocumento').textContent = 
        verificacao.tipoDocumento || '-';

    // Carregar imagem
    if (verificacao.documentoUrl) {
        try {
            const url = await storage.refFromURL(verificacao.documentoUrl).getDownloadURL();
            document.getElementById('detailImagem').src = url;
            document.getElementById('downloadBtn').href = url;
        } catch (error) {
            console.error('Erro ao carregar imagem:', error);
            showToast('Erro ao carregar imagem do comprovante', 'error');
        }
    }

    // Resetar formulário de rejeição
    document.getElementById('rejeicaoForm').style.display = 'none';
    document.getElementById('motivoRejeicao').value = '';

    // Mostrar modal
    document.getElementById('modalDetalhes').classList.add('active');
}

// Fechar modal
function closeModal() {
    document.getElementById('modalDetalhes').classList.remove('active');
    currentVerification = null;
}

// Atualizar transformação da imagem
function updateImageTransform() {
    const img = document.getElementById('detailImagem');
    img.style.transform = `scale(${imageZoom}) rotate(${imageRotation}deg)`;
}

// Aprovar verificação
async function aprovarVerificacao(verificacao) {
    try {
        const processarVerificacao = functions.httpsCallable('processarVerificacaoResidencia');
        
        await processarVerificacao({
            verificacaoId: verificacao.id,
            aprovado: true,
            motivo: ''
        });

        showToast('Verificação aprovada com sucesso!', 'success');
        closeModal();
        loadVerificacoes();
        loadEstatisticas();

    } catch (error) {
        console.error('Erro ao aprovar:', error);
        showToast('Erro ao aprovar verificação: ' + error.message, 'error');
    }
}

// Rejeitar verificação
async function rejeitarVerificacao(verificacao, motivo) {
    try {
        const processarVerificacao = functions.httpsCallable('processarVerificacaoResidencia');
        
        await processarVerificacao({
            verificacaoId: verificacao.id,
            aprovado: false,
            motivo: motivo
        });

        showToast('Verificação rejeitada', 'info');
        closeModal();
        loadVerificacoes();
        loadEstatisticas();

    } catch (error) {
        console.error('Erro ao rejeitar:', error);
        showToast('Erro ao rejeitar verificação: ' + error.message, 'error');
    }
}

// Carregar histórico
async function loadHistorico() {
    const list = document.getElementById('historicoList');
    list.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i><p>Carregando histórico...</p></div>';

    try {
        const snapshot = await db.collection('verificacoes_residencia')
            .where('status', 'in', ['aprovado', 'rejeitado'])
            .orderBy('dataProcessamento', 'desc')
            .limit(50)
            .get();

        list.innerHTML = '';

        if (snapshot.empty) {
            list.innerHTML = '<div class="empty-state"><i class="fas fa-inbox"></i><h3>Nenhum histórico encontrado</h3></div>';
            return;
        }

        for (const doc of snapshot.docs) {
            const data = doc.data();
            const userDoc = await db.collection('usuarios').doc(data.usuarioId).get();
            const userData = userDoc.data();

            const card = createHistoricoCard({
                id: doc.id,
                ...data,
                usuario: userData
            });
            list.appendChild(card);
        }

    } catch (error) {
        console.error('Erro ao carregar histórico:', error);
        list.innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-circle"></i><h3>Erro ao carregar histórico</h3></div>';
    }
}

// Criar card de histórico
function createHistoricoCard(verificacao) {
    const card = document.createElement('div');
    card.className = 'verificacao-card';
    
    const statusClass = verificacao.status === 'aprovado' ? 'success' : 'danger';
    const statusIcon = verificacao.status === 'aprovado' ? 'fa-check-circle' : 'fa-times-circle';
    const statusLabel = verificacao.status === 'aprovado' ? 'Aprovado' : 'Rejeitado';
    
    const dataProcessamento = verificacao.dataProcessamento?.toDate();
    const dataFormatada = dataProcessamento ? 
        new Intl.DateTimeFormat('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(dataProcessamento) : '-';

    card.innerHTML = `
        <div class="verificacao-icon ${statusClass}">
            <i class="fas ${statusIcon}"></i>
        </div>
        <div class="verificacao-info">
            <h3>${verificacao.usuario?.nome || 'Usuário'}</h3>
            <div class="verificacao-meta">
                <span>
                    <i class="fas fa-envelope"></i>
                    ${verificacao.usuario?.email || '-'}
                </span>
                <span>
                    <i class="fas fa-clock"></i>
                    ${dataFormatada}
                </span>
                <span>
                    <i class="fas fa-info-circle"></i>
                    ${statusLabel}
                </span>
            </div>
            ${verificacao.motivo ? `<p style="margin-top: 0.5rem; color: var(--text-secondary);"><strong>Motivo:</strong> ${verificacao.motivo}</p>` : ''}
        </div>
    `;

    return card;
}

// Filtrar histórico
function filterHistorico(search) {
    const cards = document.querySelectorAll('#historicoList .verificacao-card');
    cards.forEach(card => {
        const text = card.textContent.toLowerCase();
        if (text.includes(search.toLowerCase())) {
            card.style.display = '';
        } else {
            card.style.display = 'none';
        }
    });
}

// Carregar estatísticas
async function loadEstatisticas() {
    try {
        // Buscar todas as verificações
        const snapshot = await db.collection('verificacoes_residencia').get();
        
        const pendentes = snapshot.docs.filter(doc => doc.data().status === 'pendente').length;
        const aprovadas = snapshot.docs.filter(doc => doc.data().status === 'aprovado').length;
        const rejeitadas = snapshot.docs.filter(doc => doc.data().status === 'rejeitado').length;
        
        const total = aprovadas + rejeitadas;
        const taxa = total > 0 ? Math.round((aprovadas / total) * 100) : 0;

        document.getElementById('statPendentes').textContent = pendentes;
        document.getElementById('statAprovadas').textContent = aprovadas;
        document.getElementById('statRejeitadas').textContent = rejeitadas;
        document.getElementById('statTaxa').textContent = taxa + '%';

    } catch (error) {
        console.error('Erro ao carregar estatísticas:', error);
    }
}

// Atualizar badges
function updateBadges(total, residencia, telefone) {
    document.getElementById('badgePendentes').textContent = total;
    document.getElementById('countTodas').textContent = total;
    document.getElementById('countResidencia').textContent = residencia;
    document.getElementById('countTelefone').textContent = telefone;
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

// Abrir página de detalhes
function openDetalhesPage(verificacao) {
    // Converter a verificação para JSON e passar via URL
    const verificationData = encodeURIComponent(JSON.stringify(verificacao));
    window.location.href = `detalhes.html?data=${verificationData}`;
}
