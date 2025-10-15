// Configuração do Firebase
// IMPORTANTE: Substitua credenciais do Firebase Console
const firebaseConfig = {
    apiKey: "teste",
    authDomain: "teste",
    projectId: "teste",
    storageBucket: "teste",
    messagingSenderId: "teste",
    appId: "1:teste:android:teste"
};

// Inicializar Firebase apenas se não estiver inicializado
if (!firebase.apps.length) {
    console.log('Inicializando Firebase...');
    firebase.initializeApp(firebaseConfig);
} else {
    console.log('Firebase já inicializado, usando instância existente');
}

// Sempre exportar os serviços (não usar const dentro de if)
const auth = firebase.auth();
const db = firebase.firestore();
const storage = firebase.storage();
const functions = firebase.functions();

// Para desenvolvimento local, descomente:
// functions.useEmulator("localhost", 5001);