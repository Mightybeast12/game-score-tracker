// Application state
class GameTracker {
    constructor() {
        this.currentGameId = null;
        this.selectedGameType = null;
        this.gameState = null;
        this.isOnline = navigator.onLine;
        this.retryCount = 0;
        this.maxRetries = 3;
        this.apiQueue = [];

        this.init();
    }

    init() {
        this.loadStoredState();
        this.setupEventListeners();
        this.checkApiUrl();
        this.loadTheme();

        // Restore game state if exists
        if (this.gameState && this.currentGameId) {
            this.restoreGameState();
        }
    }

    loadStoredState() {
        try {
            const stored = localStorage.getItem('gameTrackerState');
            if (stored) {
                const state = JSON.parse(stored);
                this.currentGameId = state.currentGameId;
                this.selectedGameType = state.selectedGameType;
                this.gameState = state.gameState;
            }
        } catch (error) {
            console.warn('Failed to load stored state:', error);
        }
    }

    saveState() {
        try {
            localStorage.setItem('gameTrackerState', JSON.stringify({
                currentGameId: this.currentGameId,
                selectedGameType: this.selectedGameType,
                gameState: this.gameState
            }));
        } catch (error) {
            console.warn('Failed to save state:', error);
        }
    }

    clearState() {
        try {
            localStorage.removeItem('gameTrackerState');
        } catch (error) {
            console.warn('Failed to clear state:', error);
        }
    }

    setupEventListeners() {
        // Online/offline detection
        window.addEventListener('online', () => {
            this.isOnline = true;
            this.hideOfflineIndicator();
            this.processQueue();
            this.showToast('🟢 Connection restored', 'success');
        });

        window.addEventListener('offline', () => {
            this.isOnline = false;
            this.showOfflineIndicator();
            this.showToast('🔴 You\'re now offline', 'error');
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.target.tagName === 'INPUT') return;

            switch (e.key.toLowerCase()) {
                case ' ':
                    e.preventDefault();
                    if (this.currentGameId) {
                        this.scorePoint('player1');
                    }
                    break;
                case 'enter':
                    e.preventDefault();
                    if (this.currentGameId) {
                        this.scorePoint('player2');
                    }
                    break;
                case 'r':
                    if (e.ctrlKey || e.metaKey) return;
                    e.preventDefault();
                    if (this.currentGameId) {
                        this.confirmReset();
                    }
                    break;
                case 'n':
                    if (e.ctrlKey || e.metaKey) return;
                    e.preventDefault();
                    this.newGame();
                    break;
                case 'h':
                    if (e.ctrlKey || e.metaKey) return;
                    e.preventDefault();
                    this.showHistory();
                    break;
            }
        });

        // Game type selector keyboard navigation
        document.querySelectorAll('.game-type-btn').forEach(btn => {
            btn.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    btn.click();
                }
            });
        });

        // Input validation
        document.getElementById('player1Name').addEventListener('input', (e) => {
            this.validatePlayerName(e.target, 'player1Error');
        });

        document.getElementById('player2Name').addEventListener('input', (e) => {
            this.validatePlayerName(e.target, 'player2Error');
        });
    }

    checkApiUrl() {
        this.apiBase = 'https://ephdwz8isk.execute-api.eu-west-2.amazonaws.com/prod';

        // In production, this would be replaced by the deployment script
        if (this.apiBase.includes('PLACEHOLDER')) {
            // Fallback for local development
            this.apiBase = window.location.hostname === 'localhost'
                ? 'http://localhost:3000'
                : '/api';
        }

        console.log('API Base URL:', this.apiBase);
    }

    loadTheme() {
        const savedTheme = localStorage.getItem('theme') || 'light';
        if (savedTheme === 'dark') {
            document.documentElement.setAttribute('data-theme', 'dark');
            document.getElementById('theme-icon').textContent = '☀️';
        }
    }

    async makeApiRequest(url, options = {}) {
        const fullUrl = `${this.apiBase}${url}`;
        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };

        const requestOptions = { ...defaultOptions, ...options };

        if (!this.isOnline) {
            throw new Error('You\'re offline. Please check your internet connection.');
        }

        for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
            try {
                const response = await fetch(fullUrl, requestOptions);

                if (!response.ok) {
                    const errorData = await response.text();
                    throw new Error(`HTTP ${response.status}: ${errorData || response.statusText}`);
                }

                return await response.json();
            } catch (error) {
                if (attempt === this.maxRetries) {
                    throw error;
                }

                // Exponential backoff
                const delay = Math.pow(2, attempt) * 1000;
                await new Promise(resolve => setTimeout(resolve, delay));

                console.warn(`API request attempt ${attempt + 1} failed:`, error.message);
            }
        }
    }

    validatePlayerName(input, errorElementId) {
        const errorElement = document.getElementById(errorElementId);
        const inputGroup = input.parentElement;

        if (!input.value.trim()) {
            this.showInputError(inputGroup, errorElement, 'Player name is required');
            return false;
        }

        if (input.value.length < 2) {
            this.showInputError(inputGroup, errorElement, 'Name must be at least 2 characters');
            return false;
        }

        this.hideInputError(inputGroup, errorElement);
        return true;
    }

    showInputError(inputGroup, errorElement, message) {
        inputGroup.classList.add('error');
        errorElement.textContent = message;
        errorElement.classList.remove('hidden');
    }

    hideInputError(inputGroup, errorElement) {
        inputGroup.classList.remove('error');
        errorElement.classList.add('hidden');
    }

    // Tennis scoring logic
    convertPoints(points, gameType = 'tennis') {
        if (gameType === 'tennis') {
            const pointMap = { 0: '0', 1: '15', 2: '30', 3: '40' };
            return pointMap[points] || points;
        }
        return points;
    }

    getTennisDisplayPoints(p1Points, p2Points) {
        // Handle deuce and advantage
        if (p1Points >= 3 && p2Points >= 3) {
            if (p1Points === p2Points) {
                return { p1: 'Deuce', p2: 'Deuce' };
            } else if (p1Points > p2Points) {
                return { p1: 'Adv', p2: '40' };
            } else {
                return { p1: '40', p2: 'Adv' };
            }
        }

        return {
            p1: this.convertPoints(p1Points),
            p2: this.convertPoints(p2Points)
        };
    }

    selectGameType(gameType) {
        this.selectedGameType = gameType;

        // Update UI
        document.querySelectorAll('.game-type-btn').forEach(btn => {
            btn.classList.remove('selected');
        });
        document.querySelector(`[data-type="${gameType}"]`).classList.add('selected');
        document.getElementById('playerSetup').classList.remove('hidden');

        this.showToast(`Selected ${gameType} game`, 'info');
    }

    async startGame() {
        if (!this.selectedGameType) {
            this.showToast('Please select a game type first', 'error');
            return;
        }

        const player1Input = document.getElementById('player1Name');
        const player2Input = document.getElementById('player2Name');

        // Validate inputs
        const isValid1 = this.validatePlayerName(player1Input, 'player1Error');
        const isValid2 = this.validatePlayerName(player2Input, 'player2Error');

        if (!isValid1 || !isValid2) {
            this.showToast('Please fix the errors above', 'error');
            return;
        }

        if (player1Input.value.trim() === player2Input.value.trim()) {
            this.showToast('Player names must be different', 'error');
            return;
        }

        const startBtn = document.getElementById('startGameBtn');
        this.setLoading(startBtn, true);

        try {
            const response = await this.makeApiRequest('/games', {
                method: 'POST',
                body: JSON.stringify({
                    player1: player1Input.value.trim(),
                    player2: player2Input.value.trim(),
                    gameType: this.selectedGameType
                })
            });

            this.currentGameId = response.game_id;
            this.gameState = {
                points: { player1: 0, player2: 0 },
                games: { player1: 0, player2: 0 },
                sets: { player1: 0, player2: 0 },
                status: 'active',
                player1: player1Input.value.trim(),
                player2: player2Input.value.trim()
            };

            this.saveState();
            this.showGameBoard();
            this.showToast('🎮 Game started!', 'success');

        } catch (error) {
            console.error('Error starting game:', error);
            this.showToast(`Failed to start game: ${error.message}`, 'error');
        } finally {
            this.setLoading(startBtn, false);
        }
    }

    showGameBoard() {
        document.getElementById('gameSetup').classList.add('hidden');
        document.getElementById('gameBoard').classList.remove('hidden');

        // Update player names
        document.getElementById('player1Display').textContent = this.gameState.player1;
        document.getElementById('player2Display').textContent = this.gameState.player2;

        this.updateScoreDisplay();
    }

    async scorePoint(player) {
        if (!this.currentGameId) return;

        const button = document.getElementById(player === 'player1' ? 'score1Btn' : 'score2Btn');
        this.setLoading(button, true);

        try {
            const response = await this.makeApiRequest('/games/score', {
                method: 'PUT',
                body: JSON.stringify({
                    game_id: this.currentGameId,
                    player: player
                })
            });

            if (response.error) {
                throw new Error(response.error);
            }

            this.gameState = {
                ...this.gameState,
                points: response.points,
                games: response.games,
                sets: response.sets,
                status: response.status,
                winner: response.winner
            };

            this.saveState();
            this.updateScoreDisplay();

            if (response.status === 'completed') {
                this.handleGameCompletion(response.winner);
            }

        } catch (error) {
            console.error('Error updating score:', error);
            this.showToast(`Failed to update score: ${error.message}`, 'error');
        } finally {
            this.setLoading(button, false);
        }
    }

    updateScoreDisplay() {
        if (!this.gameState) return;

        const { points, games, sets } = this.gameState;

        // Update scores
        document.getElementById('sets1').textContent = sets.player1 || 0;
        document.getElementById('sets2').textContent = sets.player2 || 0;
        document.getElementById('games1').textContent = games.player1 || 0;
        document.getElementById('games2').textContent = games.player2 || 0;

        // Handle tennis points display with deuce/advantage
        if (this.selectedGameType === 'tennis') {
            const tennisPoints = this.getTennisDisplayPoints(points.player1, points.player2);
            document.getElementById('points1').textContent = tennisPoints.p1;
            document.getElementById('points2').textContent = tennisPoints.p2;
        } else {
            document.getElementById('points1').textContent = points.player1 || 0;
            document.getElementById('points2').textContent = points.player2 || 0;
        }

        // Update player section highlighting
        this.updatePlayerHighlighting();
    }

    updatePlayerHighlighting() {
        const player1Section = document.getElementById('player1Section');
        const player2Section = document.getElementById('player2Section');

        player1Section.classList.remove('winning');
        player2Section.classList.remove('winning');

        if (this.gameState.status === 'active') {
            // Highlight leading player
            const p1Total = (this.gameState.sets.player1 * 100) + (this.gameState.games.player1 * 10) + this.gameState.points.player1;
            const p2Total = (this.gameState.sets.player2 * 100) + (this.gameState.games.player2 * 10) + this.gameState.points.player2;

            if (p1Total > p2Total) {
                player1Section.classList.add('winning');
            } else if (p2Total > p1Total) {
                player2Section.classList.add('winning');
            }
        }
    }

    handleGameCompletion(winner) {
        const winnerName = winner === 'player1' ? this.gameState.player1 : this.gameState.player2;

        document.getElementById('gameStatus').innerHTML = `
            <div class="game-status winner">
                🏆 ${winnerName} Wins!
            </div>
        `;

        // Highlight winner
        const winnerSection = document.getElementById(winner === 'player1' ? 'player1Section' : 'player2Section');
        winnerSection.classList.add('winning');

        // Disable score buttons
        document.getElementById('score1Btn').disabled = true;
        document.getElementById('score2Btn').disabled = true;

        this.showToast(`🎉 Congratulations ${winnerName}!`, 'success');

        // Clear saved state since game is complete
        this.clearState();
    }

    confirmReset() {
        if (confirm('Are you sure you want to reset the current game? This action cannot be undone.')) {
            this.resetGame();
        }
    }

    resetGame() {
        this.gameState = {
            ...this.gameState,
            points: { player1: 0, player2: 0 },
            games: { player1: 0, player2: 0 },
            sets: { player1: 0, player2: 0 },
            status: 'active',
            winner: null
        };

        this.updateScoreDisplay();
        document.getElementById('gameStatus').innerHTML = '';

        // Re-enable score buttons
        document.getElementById('score1Btn').disabled = false;
        document.getElementById('score2Btn').disabled = false;

        this.saveState();
        this.showToast('Game reset', 'info');
    }

    newGame() {
        this.currentGameId = null;
        this.selectedGameType = null;
        this.gameState = null;
        this.clearState();

        // Reset UI
        document.getElementById('gameSetup').classList.remove('hidden');
        document.getElementById('gameBoard').classList.add('hidden');
        document.getElementById('playerSetup').classList.add('hidden');
        document.getElementById('gameStatus').innerHTML = '';

        // Reset form
        document.getElementById('player1Name').value = '';
        document.getElementById('player2Name').value = '';
        document.querySelectorAll('.game-type-btn').forEach(btn => {
            btn.classList.remove('selected');
        });

        // Clear input errors
        document.querySelectorAll('.input-group').forEach(group => {
            group.classList.remove('error');
        });
        document.querySelectorAll('.input-error').forEach(error => {
            error.classList.add('hidden');
        });

        // Re-enable buttons
        document.getElementById('score1Btn').disabled = false;
        document.getElementById('score2Btn').disabled = false;
    }

    async showHistory() {
        const modal = document.getElementById('historyModal');
        const historyList = document.getElementById('historyList');

        historyList.innerHTML = '<div class="loading">Loading game history...</div>';
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');

        try {
            const response = await this.makeApiRequest('/games/history');
            this.displayHistory(response.games);
        } catch (error) {
            console.error('Error fetching history:', error);
            historyList.innerHTML = `<div class="error">Failed to load history: ${error.message}</div>`;
        }
    }

    displayHistory(games) {
        const historyList = document.getElementById('historyList');

        if (!games || games.length === 0) {
            historyList.innerHTML = '<p>No games found. Start playing to build your history!</p>';
            return;
        }

        historyList.innerHTML = games.map(game => {
            const date = new Date(game.created_at).toLocaleString();
            const gameTypeIcon = this.getGameTypeIcon(game.game_type);

            let status = '';
            if (game.status === 'completed') {
                const winnerName = game.winner === 'player1' ? game.player1 : game.player2;
                status = `<div class="history-status completed">🏆 Winner: ${winnerName}</div>`;
            } else {
                status = '<div class="history-status in-progress">⏱️ In Progress</div>';
            }

            const tennisPoints = this.selectedGameType === 'tennis'
                ? this.getTennisDisplayPoints(game.points.player1, game.points.player2)
                : { p1: game.points.player1, p2: game.points.player2 };

            return `
                <div class="history-item">
                    <div class="history-header">
                        <div class="history-matchup">
                            ${gameTypeIcon} ${game.player1} vs ${game.player2}
                        </div>
                        <div class="history-date">${date}</div>
                    </div>
                    <div class="history-scores">
                        <div class="history-score">
                            <strong>Sets:</strong><br>
                            ${game.sets.player1} - ${game.sets.player2}
                        </div>
                        <div class="history-score">
                            <strong>Games:</strong><br>
                            ${game.games.player1} - ${game.games.player2}
                        </div>
                        <div class="history-score">
                            <strong>Points:</strong><br>
                            ${tennisPoints.p1} - ${tennisPoints.p2}
                        </div>
                    </div>
                    ${status}
                </div>
            `;
        }).join('');
    }

    getGameTypeIcon(gameType) {
        const icons = {
            tennis: '🎾',
            football: '⚽',
            rugby: '🏉'
        };
        return icons[gameType] || '🎮';
    }

    closeHistory() {
        const modal = document.getElementById('historyModal');
        modal.classList.remove('show');
        modal.setAttribute('aria-hidden', 'true');
    }

    async exportData() {
        try {
            const response = await this.makeApiRequest('/games/history');
            const data = {
                exportDate: new Date().toISOString(),
                games: response.games,
                totalGames: response.games.length,
                completedGames: response.games.filter(g => g.status === 'completed').length
            };

            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);

            const a = document.createElement('a');
            a.href = url;
            a.download = `game-tracker-export-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);

            this.showToast('📥 Data exported successfully', 'success');
        } catch (error) {
            console.error('Export failed:', error);
            this.showToast('Failed to export data', 'error');
        }
    }

    restoreGameState() {
        this.showGameBoard();

        if (this.gameState.status === 'completed') {
            this.handleGameCompletion(this.gameState.winner);
        }
    }

    toggleTheme() {
        const currentTheme = document.documentElement.getAttribute('data-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

        document.documentElement.setAttribute('data-theme', newTheme);
        document.getElementById('theme-icon').textContent = newTheme === 'dark' ? '☀️' : '🌙';

        localStorage.setItem('theme', newTheme);
        this.showToast(`Switched to ${newTheme} mode`, 'info');
    }

    showOfflineIndicator() {
        document.getElementById('offlineIndicator').classList.add('show');
    }

    hideOfflineIndicator() {
        document.getElementById('offlineIndicator').classList.remove('show');
    }

    showToast(message, type = 'info') {
        const toast = document.getElementById('toast');
        const icon = document.getElementById('toastIcon');
        const messageElement = document.getElementById('toastMessage');

        const icons = {
            success: '✅',
            error: '❌',
            info: 'ℹ️',
            warning: '⚠️'
        };

        icon.textContent = icons[type] || icons.info;
        messageElement.textContent = message;

        toast.className = `toast ${type} show`;

        // Auto-hide after 4 seconds
        setTimeout(() => {
            toast.classList.remove('show');
        }, 4000);
    }

    setLoading(element, loading) {
        if (loading) {
            element.disabled = true;
            element.classList.add('loading');
        } else {
            element.disabled = false;
            element.classList.remove('loading');
        }
    }

    processQueue() {
        // Process any queued API calls when connection is restored
        // This could be implemented for offline support
        console.log('Processing API queue...');
    }
}

// Global functions for HTML onclick handlers
let gameTracker;

function selectGameType(gameType) {
    gameTracker.selectGameType(gameType);
}

function startGame() {
    gameTracker.startGame();
}

function scorePoint(player) {
    gameTracker.scorePoint(player);
}

function newGame() {
    gameTracker.newGame();
}

function confirmReset() {
    gameTracker.confirmReset();
}

function showHistory() {
    gameTracker.showHistory();
}

function closeHistory() {
    gameTracker.closeHistory();
}

function exportData() {
    gameTracker.exportData();
}

function toggleTheme() {
    gameTracker.toggleTheme();
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    gameTracker = new GameTracker();
});
