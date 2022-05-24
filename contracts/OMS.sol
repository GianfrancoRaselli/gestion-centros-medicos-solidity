// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;


contract OMS {

  // direccion de la OMS -> dueño del contrato
  address public direccionOMS = msg.sender;

  // mapping para relacionar centros de salud con la validez del sistema de gestion
  mapping(address => bool) public centrosSaludValidados;

  // relacionar una direccion de un centro de salud con su contrato
  mapping(address => address) public centroSaludContrato;

  // array que almacene las direcciones de los smart contracts de los centros de salud creados
  address[] public centrosSaludCreados;

  // array de las direcciones que soliciten acceso
  address[] solicitudes;


  // eventos a emitir
  event AccesoSolicitado(address);
  event NuevoCentroSaludValidado(address);
  event NuevoCentroSaludCreado(address, address);


  // modificador que permita unicamente la ejecucion de una funcion por la OMS
  modifier unicamenteOMS {
    require(msg.sender == direccionOMS, "No tienes permisos para realizar esta funcion");
    _;
  }


  // funcion para solicitar acceso al sistema medido
  function solicitarAcceso() public {
    // almacenar la direccion en el array de solicitudes
    solicitudes.push(msg.sender);

    // emision del evento
    emit AccesoSolicitado(msg.sender);
  }

  // funcion para visualizar las direcciones que han solicitado acceso
  function visualizarSolicitudes() public view unicamenteOMS() returns (address[] memory) {
    return solicitudes;
  }

  // funcion para validar nuevos centros de salud que puedan autogestionarse
  function validarCentroSalud(address _centroSalud) public unicamenteOMS() {
    // asignacion del estado de validez al centro de salud
    centrosSaludValidados[_centroSalud] = true;

    // emision del evento
    emit NuevoCentroSaludValidado(_centroSalud);
  }

  // funcion que permita crear un nuevo centro de salud
  function crearCentroSalud() public {
    // filtrado para que unicamente los centros de salud validados sean capaces de ejecutar esta funcion
    require(centrosSaludValidados[msg.sender], "No tienes permisos para ejecutar esta funcion");

    // crear un nuevo centro de salud (nuevo smart contract)
    address direccionContratoCentroSalud = address(new CentroSalud(msg.sender));

    // almacenamiento de la direccion del contrato en el array
    centrosSaludCreados.push(direccionContratoCentroSalud);

    // relacion entre el centro de salud y su contrato
    centroSaludContrato[msg.sender] = direccionContratoCentroSalud;

    // emision del evento
    emit NuevoCentroSaludCreado(direccionContratoCentroSalud, msg.sender);
  }

}


// contrato autogestinable por el centro de salud
contract CentroSalud {

  // direccion del centro de salud (owner del contrato)
  address public direccionCentroSalud;

  // estructura de los resultados
  struct ResultadoCOVID {
    uint fecha;
    bool diagnostico;
    string codigoIPFS;
  }

  // mapping para relacionar el hash de la persona con los resultados
  mapping(bytes32 => ResultadoCOVID[]) resultadosCOVID;


  // eventos
  event NuevoResultado(uint, bool, string);


  // filtrar las funciones a ejecutar por el centro de salud
  modifier unicamenteCentroSalud() {
    require(msg.sender == direccionCentroSalud, "No tienes permisos para ejecutar esta funcion");
    _;
  }


  constructor(address _direccionCentroSalud) {
    direccionCentroSalud = _direccionCentroSalud;
  }


  // funcion para emitir un resultado de una prueba de COVID
  function resultadoPruebaCovid(string memory _idPersona, bool _resultadoCOVID, string memory _codigoIPFS) public unicamenteCentroSalud() {
    // hash de la identificacion de la persona
    bytes32 hashIdPersona = keccak256(abi.encodePacked(_idPersona));

    // relacion entre el hash de la persona con la estructura de resultados
    resultadosCOVID[hashIdPersona].push(ResultadoCOVID(block.timestamp, _resultadoCOVID, _codigoIPFS));

    // emision del evento
    emit NuevoResultado(block.timestamp, _resultadoCOVID, _codigoIPFS);
  }

  // funcion que permita la visualizacion de un resultado
  function visualizarResultado(string memory _idPersona, uint _nroPrueba) public view returns (uint fecha, bool resultado, string memory codigoIPFS) {
    // resultado de la prueba
    ResultadoCOVID memory resultadoCOVID = resultadosCOVID[keccak256(abi.encodePacked(_idPersona))][_nroPrueba];

    // devolucion del resultado
    return (resultadoCOVID.fecha, resultadoCOVID.diagnostico, resultadoCOVID.codigoIPFS);
  }

}
