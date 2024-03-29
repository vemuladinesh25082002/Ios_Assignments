// WeatherViewModel.swift

import Foundation
import CoreLocation
struct Constants
{
    static let apiKey:String = "609208b6d272befd85b3fbcd4aaeb21f"
    static let baseURL:String = "https://api.openweathermap.org/data/2.5/"
}
class WeatherViewModel: NSObject, CLLocationManagerDelegate {
    var weatherModel: WeatherModel?
    var errorMessage: String?
    let locationManager = CLLocationManager()
    

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Location Manager Setup

    func setupLocationManager() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }

    //Session and Data Retrieval

    func fetchData(with url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "No Data", code: 1, userInfo: nil)
                completion(.failure(noDataError))
                return
            }

            completion(.success(data))
        }
        task.resume()
    }

    //Weather Data Fetching for any city

    func fetchWeatherData(for city: String, completion: @escaping (Result<WeatherModel, Error>) -> Void) {
        //let apiKey = "609208b6d272befd85b3fbcd4aaeb21f"
        let urlString = Constants.baseURL + "weather?q=\(city)&appid=\(Constants.apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        fetchData(with: url) { result in
            switch result {
            case .success(let data):
                self.decodeWeatherData(data: data, completion: completion)
            case .failure(let error):
                self.errorMessage = "Error fetching weather data: \(error)"
                completion(.failure(error))
            }
        }
    }
    //Weather Data Fetching for live location
    func fetchWeatherDataForCurrentLocation(completion: @escaping (Result<WeatherModel, Error>) -> Void) {
        guard let location = locationManager.location else {
            let locationError = NSError(domain: "Location Error", code: 2, userInfo: nil)
            completion(.failure(locationError))
            return
        }
        let urlString = Constants.baseURL + "weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(Constants.apiKey)"

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        fetchData(with: url) { result in
            switch result {
            case .success(let data):
                self.decodeWeatherData(data: data, completion: completion)
            case .failure(let error):
                self.errorMessage = "Error fetching weather data: \(error)"
                completion(.failure(error))
            }
        }
    }

    //JSON Decoding

    func decodeWeatherData(data: Data, completion: @escaping (Result<WeatherModel, Error>) -> Void) {
        let decoder = JSONDecoder()
        do {
            let weatherModel = try decoder.decode(WeatherModel.self, from: data)
            if !weatherModel.main.temp.isNaN {
                self.weatherModel = weatherModel
                self.errorMessage = nil
                completion(.success(weatherModel))
            } else {
                self.errorMessage = "Invalid temperature data"
                completion(.failure(NSError(domain: "Invalid Data", code: 3, userInfo: nil)))
            }
        } catch {
            self.errorMessage = "Error decoding JSON: \(error)"
            completion(.failure(error))
        }
    }
}
