
import UIKit
import AVFoundation


class gameController: UIViewController {//outlets
    @IBOutlet weak var questionLbl: UILabel!
    @IBOutlet weak var btn4: UIButton!
    @IBOutlet weak var btn3: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var barTimer: UIProgressView!
    @IBOutlet weak var categoriaLbl: UILabel!
    @IBOutlet weak var vidas: UILabel!
    
    var audioPlayerCorrect: AVAudioPlayer?
    var audioPlayerInCorrect: AVAudioPlayer?
    var audioPlayerEnd: AVAudioPlayer?
    
    
    let gameViewModel = GameViewModel()
    let userViewModel = UserViewModel()
    var allQuestions: [Question] = []
    var pregunta = ""
    var categoria = ""
    var correcta = ""
    var incorrecta1 = ""
    var incorrecta2 = ""
    var incorrecta3 = ""
    var puntos = 0
    var vidasUser = 0
    
    
    var puntuacion = 0
    
    var endGameCond = false
    
    var currentQuestionIndex = 0
    var timer: Timer?
    var timerrGoodEnding: Timer?
    
    var currentQuestion = Question(categoria: "", correcta: "", incorrecta1: "", incorrecta2: "", incorrecta3: "", pregunta: "", puntos: 0, id: "")
    
    var firstTime = true
    var progressAnimator = UIViewPropertyAnimator()
    var timeOutBool = false
    
    var time = 15
    
    var buttonPressed = false
    
    var ended = false
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Reachability.isConnectedToNetwork(){
            cargarAudioCorrect()
            cargarAudioIncorrect()
            cargarAudioEnd()
            gameViewModel.fetchData {
                print("dataFetched")
                
                self.allQuestions = self.gameViewModel.questions
                self.allQuestions.shuffle()
                self.startQuestionTimer()
                self.configureButton(for: self.btn1)
                self.configureButton(for: self.btn2)
                self.configureButton(for: self.btn3)
                self.configureButton(for: self.btn4)
                
                
            }
        } else {
            let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
            
            // Agregar acciones (botones) a la alerta
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                self.viewDidLoad()
            }
            alertController.addAction(okAction)
            
            // Mostrar la alerta
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        }
    
    
        
        
        func startQuestionTimer() {
            // Configurar y comenzar el temporizador
            userViewModel.fetchData {
                self.vidasUser = self.userViewModel.fetchedUser.vidas
                if self.vidasUser <= 0{
                    self.endGame()
                } else {
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
                    
                    // Mostrar la primera pregunta inmediatamente al iniciar la vista
                    self.showNextQuestion()
                    
                    
                    
                    
                }            }
            
            
        }
        
        @objc func updateTime() {
            time -= 1
            if time <= 0{
                self.timeOut()
                print("timeout")
            }
        }
        
        func goodEnding(){
            self.ended = true
            timer?.invalidate()
            let alertController = UIAlertController(title: "Felicidades :)", message: "Tu puntaje total fue de: " + String(self.puntuacion), preferredStyle: .alert)
            userViewModel.updateScore(score: self.puntuacion, type: "general")
            
            // Agregar acciones (botones) a la alerta
            let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                // Código a ejecutar cuando se presiona el botón OK
                print("Botón OK presionado")
                let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                self.present(profileController, animated: true, completion: nil)        }
            alertController.addAction(okAction)
            
            // Mostrar la alerta
            self.present(alertController, animated: true, completion: nil)
            if let audioPlayer = audioPlayerEnd, audioPlayerEnd?.isPlaying == false {
                audioPlayer.play()
                
            }
            
            
        }
        
        
        func endGame(){
            
            if self.vidasUser > 0{
                if self.buttonPressed{
                    self.goodEnding()
                    self.ended = true
                    
                    
                } else if !self.ended {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15){
                        self.timeOutAux()
                        self.goodEnding()
                        self.ended = true
                    }
                }
            }
            
            else {
                
                let alertController = UIAlertController(title: "Te quedaste sin vidas", message: "Espera un tiempo para volver a jugar :)", preferredStyle: .alert)
                
                // Agregar acciones (botones) a la alerta
                let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                    // Código a ejecutar cuando se presiona el botón OK
                    print("Botón OK presionado")
                    let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                    self.present(profileController, animated: true, completion: nil)
                    
                }
                alertController.addAction(okAction)
                
                // Mostrar la alerta
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
                
                progressAnimator.stopAnimation(true)
                progressAnimator.finishAnimation(at: .current)
                self.ended = true
            }
            
        }
        
        
        
        
        func showNextQuestion() {

            var switchBool = false
            // fetching and update lifes
            self.userViewModel.fetchData {
                self.userViewModel.updateCT(cOt: false)
                let fUser = self.userViewModel.fetchedUser
                self.vidasUser = fUser.vidas
                self.vidas.text = "x " + String(self.vidasUser)
                
                if  self.currentQuestionIndex >= self.allQuestions.count || self.vidasUser <= 0 {
                    print("Vidas:", self.vidasUser)
                    self.timer?.invalidate()
                    self.endGame()
                    switchBool = true
                    
                }
            }
            
            if self.currentQuestionIndex >= self.allQuestions.count || switchBool {
                return
            }
            print(allQuestions.count, self.currentQuestionIndex)
            // Obtener la pregunta actual
            let pregunta = allQuestions[currentQuestionIndex]
            
            
            //Lifes Update
            updateLocalData(preguntaI: pregunta)
            self.firstTime = false
            loadQuestion(preguntaI: pregunta)
            print(puntuacion)
            
            
            // Incrementar el índice de la pregunta actual
            currentQuestionIndex += 1
            
            //Progress bar
            animateProgressBar()
            
            
            
            
        }
        
        func updateScoreFB(){
            self.userViewModel.updateScore(score: 1, type: self.categoria)
            
            
            
        }
        
        func animateProgressBar(){
            print("animation!")
            barTimer.progress = 0.0
            self.view.layoutIfNeeded()
            progressAnimator = UIViewPropertyAnimator(duration: 15, curve: .linear){
                self.barTimer.setProgress(1.0, animated: true)
            }
            progressAnimator.startAnimation()
            
            
        }
    
    func configureButton(for button: UIButton) {
        button.layer.cornerRadius = 8.0 // Ajusta según sea necesario
        button.layer.masksToBounds = true
        button.setTitle(title, for: .normal)
        button.titleLabel?.textAlignment = .center
    }
        
        func loadQuestion(preguntaI: Question) {
            var respuestas = [preguntaI.correcta, preguntaI.incorrecta1, preguntaI.incorrecta2, preguntaI.incorrecta3].shuffled()
            
            btn1.setTitle(respuestas.popLast(), for: .normal)
            btn2.setTitle(respuestas.popLast(), for: .normal)
            btn3.setTitle(respuestas.popLast(), for: .normal)
            btn4.setTitle(respuestas.popLast(), for: .normal)
            
            btn1.isEnabled = true
            btn2.isEnabled = true
            btn3.isEnabled = true
            btn4.isEnabled = true
            
            btn1.backgroundColor = #colorLiteral(red: 0.9137254902, green: 0.9137254902, blue: 0.9215686275, alpha: 1)
            btn2.backgroundColor = #colorLiteral(red: 0.9137254902, green: 0.9137254902, blue: 0.9215686275, alpha: 1)
            btn3.backgroundColor = #colorLiteral(red: 0.9137254902, green: 0.9137254902, blue: 0.9215686275, alpha: 1)
            btn4.backgroundColor = #colorLiteral(red: 0.9137254902, green: 0.9137254902, blue: 0.9215686275, alpha: 1)
            
            
            btn1.setTitleColor(UIColor.lightGray, for: .disabled)
            btn2.setTitleColor(UIColor.lightGray, for: .disabled)
            btn3.setTitleColor(UIColor.lightGray, for: .disabled)
            btn4.setTitleColor(UIColor.lightGray, for: .disabled)
            
            questionLbl.text = preguntaI.pregunta
            categoriaLbl.text = preguntaI.categoria
            
            
            
            if categoria == "Signos Vitales" {
                categoriaLbl.backgroundColor = UIColor(red: 0.729, green: 0.890, blue: 0.820, alpha: 1.0)
            } else if categoria == "Curación"{
                categoriaLbl.backgroundColor = UIColor(red: 1.000, green: 0.796, blue: 0.796, alpha: 1.0)
            } else if categoria == "Síntomas" {
                categoriaLbl.backgroundColor = UIColor(red: 0.788, green: 0.847, blue: 1.000, alpha: 1.0)
            }else if categoria == "Anatomía" {
                categoriaLbl.backgroundColor = UIColor(red: 1.000, green: 1.000, blue: 0.710, alpha: 1.0)
            }else {
                categoriaLbl.backgroundColor = UIColor(red: 0.788, green: 0.710, blue: 1.000, alpha: 1.0)
            }
            self.buttonPressed = false
            
            
        }
        
        func updateLocalData(preguntaI: Question){
            pregunta = preguntaI.pregunta
            categoria = preguntaI.categoria
            correcta = preguntaI.correcta
            incorrecta1 = preguntaI.incorrecta1
            incorrecta2 = preguntaI.incorrecta2
            incorrecta3 = preguntaI.incorrecta3
            puntos = preguntaI.puntos
        }
        
        func resCorrecta(button:UIButton){
            if let audioPlayer = audioPlayerCorrect, audioPlayerCorrect?.isPlaying == false {
                audioPlayer.play()
            }
            
            userViewModel.updateCT(cOt: true)
            button.backgroundColor = UIColor.green
            puntuacion += puntos
            updateScoreFB()
            
            
        }
        
        func resIncorrecta(button:UIButton){
            if let audioPlayer = audioPlayerInCorrect, audioPlayerInCorrect?.isPlaying == false {
                audioPlayer.play()
            }
            button.backgroundColor = UIColor.red
            if self.vidasUser>1{
                self.userViewModel.updateLives(newLives: vidasUser - 1)
                vidas.text = "x " + String(self.vidasUser - 1)
            } else {
                self.vidasUser = 0
                vidas.text = "x 0"
                self.userViewModel.updateLives(newLives: vidasUser)
            }
            if !self.ended {
                if btn1.titleLabel?.text == correcta {
                    btn1.backgroundColor = UIColor.green
                    btn1.setTitleColor(UIColor.black, for: .disabled)
                } else if btn2.titleLabel?.text == correcta {
                    btn2.backgroundColor = UIColor.green
                    btn2.setTitleColor(UIColor.black, for: .disabled)
                } else if btn3.titleLabel?.text == correcta {
                    btn3.backgroundColor = UIColor.green
                    btn3.setTitleColor(UIColor.black, for: .disabled)
                } else if btn4.titleLabel?.text == correcta {
                    
                    btn4.backgroundColor = UIColor.green
                    btn4.setTitleColor(UIColor.black, for: .disabled)
                }
            }
            
        }
        
        func cargarAudioCorrect() {
            if let path = Bundle.main.path(forResource: "success", ofType: "mp3") {
                do {
                    self.audioPlayerCorrect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                } catch {
                    print("Error al cargar el archivo de audio")
                }
            }
        }
        func cargarAudioIncorrect() {
            if let path = Bundle.main.path(forResource: "negative", ofType: "mp3") {
                do {
                    self.audioPlayerInCorrect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                } catch {
                    print("Error al cargar el archivo de audio")
                }
            }
        }
        
        func cargarAudioEnd() {
            if let path = Bundle.main.path(forResource: "end", ofType: "mp3") {
                do {
                    self.audioPlayerEnd = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                } catch {
                    print("Error al cargar el archivo de audio")
                }
            }
        }
        
        
        
        
        func timeOut(){
            if Reachability.isConnectedToNetwork(){
                        //code
                if !self.ended {
                    if let audioPlayer = audioPlayerInCorrect, audioPlayerInCorrect?.isPlaying == false {
                        audioPlayer.play()
                    }
                    timeOutAux()
                    timer?.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                        self.time = 15
                        self.startQuestionTimer()
                    }
                }
                        
                    } else {
                        let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
                        
                        // Agregar acciones (botones) a la alerta
                        let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                            let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                                          self.present(profileController, animated: true, completion: nil)
                            
                        }
                        alertController.addAction(okAction)
                        
                        // Mostrar la alerta
                        self.present(alertController, animated: true, completion: nil)
                    }
           
        }
        
        func timeOutAux(){
            
            if !self.ended {
                if btn1.titleLabel?.text == correcta {
                    btn1.backgroundColor = UIColor.green
                    btn2.backgroundColor = UIColor.red
                    btn3.backgroundColor = UIColor.red
                    btn4.backgroundColor = UIColor.red
                    
                } else if btn2.titleLabel?.text == correcta {
                    btn1.backgroundColor = UIColor.red
                    btn2.backgroundColor = UIColor.green
                    btn3.backgroundColor = UIColor.red
                    btn4.backgroundColor = UIColor.red
                } else if btn3.titleLabel?.text == correcta {
                    btn1.backgroundColor = UIColor.red
                    btn2.backgroundColor = UIColor.red
                    btn3.backgroundColor = UIColor.green
                    btn4.backgroundColor = UIColor.red
                } else if btn4.titleLabel?.text == correcta {
                    btn1.backgroundColor = UIColor.red
                    btn2.backgroundColor = UIColor.red
                    btn3.backgroundColor = UIColor.red
                    btn4.backgroundColor = UIColor.green
                }
                
                
                if self.vidasUser>1{
                    self.userViewModel.updateLives(newLives: vidasUser - 1)
                    vidas.text = "x " + String(self.vidasUser - 1)
                } else {
                    self.vidasUser = 0
                    vidas.text = "x 0"
                    self.userViewModel.updateLives(newLives: vidasUser)
                }
                DispatchQueue.main.async {
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        
        @IBAction func btn1Tap(_ sender: Any) {
            if Reachability.isConnectedToNetwork(){
                        //code
                btn1.isEnabled = false
                btn2.isEnabled = false
                btn3.isEnabled = false
                btn4.isEnabled = false
                
                
                progressAnimator.stopAnimation(true)
                progressAnimator.finishAnimation(at: .current)
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    self.time = 15
                    self.buttonPressed = true
                    if self.currentQuestionIndex < self.allQuestions.count{
                        self.startQuestionTimer()
                    } else {
                        self.goodEnding()
                    }
                    
                }
                
                btn1.setTitleColor(UIColor.black, for: .disabled)
                if btn1.titleLabel!.text == correcta {
                    resCorrecta(button: btn1)
                } else {
                    resIncorrecta(button: btn1)
                }
                
                        
                    } else {
                        let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
                        
                        // Agregar acciones (botones) a la alerta
                        let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                            let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                            self.present(profileController, animated: true, completion: nil)
                            
                        }
                        alertController.addAction(okAction)
                        
                        // Mostrar la alerta
             DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
            }
                    }
            
        }
        
        @IBAction func btn2Tap(_ sender: Any) {
            if Reachability.isConnectedToNetwork(){
                        //code
                btn1.isEnabled = false
                btn2.isEnabled = false
                btn3.isEnabled = false
                btn4.isEnabled = false
                
                progressAnimator.stopAnimation(true)
                progressAnimator.finishAnimation(at: .current)
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    self.time = 15
                    self.buttonPressed = true
                    if self.currentQuestionIndex < self.allQuestions.count{
                        self.startQuestionTimer()
                    } else {
                        self.goodEnding()
                    }
                }
                
                btn2.setTitleColor(UIColor.black, for: .disabled)
                if btn2.titleLabel!.text == correcta {
                    resCorrecta(button: btn2)
                } else {
                    resIncorrecta(button: btn2)
                }
                        
                    } else {
                        let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
                        
                        // Agregar acciones (botones) a la alerta
                        let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                            let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                            self.present(profileController, animated: true, completion: nil)
                            
                        }
                        alertController.addAction(okAction)
                        
                        // Mostrar la alerta
             DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
            }
                    }
            
        }
        
        @IBAction func btn3Tap(_ sender: Any) {
            if Reachability.isConnectedToNetwork(){
                        //code
                btn1.isEnabled = false
                btn2.isEnabled = false
                btn3.isEnabled = false
                btn4.isEnabled = false
                
                
                
                
                progressAnimator.stopAnimation(true)
                progressAnimator.finishAnimation(at: .current)
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    self.time = 15
                    self.buttonPressed = true
                    if self.currentQuestionIndex < self.allQuestions.count{
                        self.startQuestionTimer()
                    } else {
                        self.goodEnding()
                    }        }
                
                btn3.setTitleColor(UIColor.black, for: .disabled)
                if btn3.titleLabel!.text == correcta {
                    resCorrecta(button: btn3)
                } else {
                    resIncorrecta(button: btn3)
                }
                        
                    } else {
                        let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
                        
                        // Agregar acciones (botones) a la alerta
                        let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                            let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                            self.present(profileController, animated: true, completion: nil)
                            
                        }
                        alertController.addAction(okAction)
                        
                        // Mostrar la alerta
             DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
            }
                    }
            
        }
        
        @IBAction func btn4Tap(_ sender: Any) {
            if Reachability.isConnectedToNetwork(){
                        //code
                btn1.isEnabled = false
                btn2.isEnabled = false
                btn3.isEnabled = false
                btn4.isEnabled = false
                
                progressAnimator.stopAnimation(true)
                progressAnimator.finishAnimation(at: .current)
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    self.time = 15
                    self.buttonPressed = true
                    if self.currentQuestionIndex < self.allQuestions.count{
                        self.startQuestionTimer()
                    } else {
                        self.goodEnding()
                    }
                    
                }
                
                
                btn4.setTitleColor(UIColor.black, for: .disabled)
                if btn4.titleLabel!.text == correcta {
                    resCorrecta(button: btn4)
                } else {
                    resIncorrecta(button: btn4)
                }
                        
                    } else {
                        let alertController = UIAlertController(title: "Conexión Perdida", message: "Reconectate y vuelve a intentar", preferredStyle: .alert)
                        
                        // Agregar acciones (botones) a la alerta
                        let okAction = UIAlertAction(title: "Inicio", style: .default) { _ in
                            let profileController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileControllerID") as! profileController
                            self.present(profileController, animated: true, completion: nil)
                            
                        }
                        alertController.addAction(okAction)
                        
                        // Mostrar la alerta
             DispatchQueue.main.async {
                        self.present(alertController, animated: true, completion: nil)
            }
                    }
            
        }
        
        @IBAction func volverBtn(_ sender: Any) {
            let alertController = UIAlertController(title: "Salir del Juego", message: "¿Desea salir del juego?", preferredStyle: .alert)

                // Agregar acciones (botones) a la alerta
                let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
                    // Handle the cancel action if needed
                }
                alertController.addAction(cancelAction)

                let deleteAction = UIAlertAction(title: "Sí", style: .destructive) { [weak self] _ in
                    // Use self?. instead of self. to avoid strong reference cycle
                    self?.stopAndReleaseAudioPlayers()

                    self?.timer?.invalidate()
                    self?.time = 15
                    self?.progressAnimator.stopAnimation(true)
                    self?.progressAnimator.finishAnimation(at: .current)
                    self?.btn1.isEnabled = false
                    self?.btn2.isEnabled = false
                    self?.btn3.isEnabled = false
                    self?.btn4.isEnabled = false
                    self?.performSegue(withIdentifier: "goBack", sender: self)
                }
                alertController.addAction(deleteAction)
            present(alertController, animated: true, completion: nil)

            
            
        }
    
    func stopAndReleaseAudioPlayers() {
        audioPlayerCorrect?.stop()
        audioPlayerCorrect = nil

        audioPlayerInCorrect?.stop()
        audioPlayerInCorrect = nil

        audioPlayerEnd?.stop()
        audioPlayerEnd = nil
    }
        
    }

