import 'package:flutter_bloc/flutter_bloc.dart';

// Mining States
abstract class MiningState {}
class MiningInitial extends MiningState {}
class MiningStarted extends MiningState {}
class MiningStopped extends MiningState {}

class MiningCubit extends Cubit<MiningState> {
  MiningCubit() : super(MiningInitial());

  void startMining() {
    // Add any additional logic for starting mining
    emit(MiningStarted());
  }

  void stopMining() {
    // Add any additional logic for stopping mining
    emit(MiningStopped());
  }
}