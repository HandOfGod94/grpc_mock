/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	grpcmockv1alpha1 "github.com/handofgod94/grpc-mock-operator/api/v1alpha1"
)

// GRPCMockReconciler reconciles a GRPCMock object
type GRPCMockReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=grpc-mock.grakh.com,resources=grpcmocks,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=grpc-mock.grakh.com,resources=grpcmocks/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=grpc-mock.grakh.com,resources=grpcmocks/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;
//+kubebuilder:rbac:groups=core,resources=configmaps,verbs=get;list;watch;create;patch;delete

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the GRPCMock object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.11.0/pkg/reconcile
func (r *GRPCMockReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	_ = log.FromContext(ctx)

	grpcMock := &grpcmockv1alpha1.GRPCMock{}
	err := r.Get(ctx, req.NamespacedName, grpcMock)
	if err != nil {
		return ctrl.Result{}, err
	}

	res, err := r.createConfigMap(ctx, grpcMock)
	if err != nil {
		return res, err
	}

	res, err = r.createDeployment(ctx, grpcMock)
	if err != nil {
		return res, err
	}

	return res, nil
}

func (r *GRPCMockReconciler) createConfigMap(ctx context.Context, grpcMock *grpcmockv1alpha1.GRPCMock) (ctrl.Result, error) {
	cfgMap := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "grpc-mock-server-sample-config",
			Namespace: grpcMock.Namespace,
		},
		Data: map[string]string{
			"kind": grpcMock.Spec.Kind,
		},
	}

	found := &corev1.ConfigMap{}
	err := r.Get(ctx, types.NamespacedName{Name: "grpc-mock-server-sample-config", Namespace: grpcMock.Namespace}, found)

	if err != nil && errors.IsNotFound(err) {
		err := r.Create(ctx, cfgMap)
		if err != nil {
			return ctrl.Result{}, err
		}
		controllerutil.SetControllerReference(grpcMock, cfgMap, r.Scheme)
	} else {
		return ctrl.Result{}, err
	}

	return ctrl.Result{Requeue: true}, nil
}

func (r *GRPCMockReconciler) createDeployment(ctx context.Context, grpcMock *grpcmockv1alpha1.GRPCMock) (ctrl.Result, error) {
	var replicas int32
	replicas = 1

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "grpc-mock-server-sample",
			Namespace: grpcMock.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{"app": "grpc-mock-server-sample"},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{"app": "grpc-mock-server-sample"},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:            "grpc-mock-server-sample",
							Command:         []string{"echo", "hello world"},
							Image:           "paulbouwer/hello-kubernetes:1.10",
							ImagePullPolicy: corev1.PullAlways,
							Ports: []corev1.ContainerPort{
								{
									Name:          "hello",
									ContainerPort: int32(grpcMock.Spec.Server.Port),
								},
							},
							Env: []corev1.EnvVar{
								{Name: "FOO", Value: "BAR"},
							},
						},
					},
				},
			},
		},
	}

	err := r.Create(ctx, dep)
	if err != nil {
		return ctrl.Result{}, err
	}

	controllerutil.SetControllerReference(grpcMock, dep, r.Scheme)
	return ctrl.Result{Requeue: true}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *GRPCMockReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&grpcmockv1alpha1.GRPCMock{}).
		Complete(r)
}
